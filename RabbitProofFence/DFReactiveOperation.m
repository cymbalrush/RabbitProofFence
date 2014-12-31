//
//  DFReactiveOperation.m
//  vf-hollywood
//
//  Created by Sinha, Gyanendra on 6/23/14.
//  Copyright (c) 2014 Conde Nast. All rights reserved.
//

#import "DFReactiveOperation.h"
#import "DFMetaOperation_SubclassingHooks.h"
#import "ReactiveConnectionInfo.h"
#import "DFSequenceGenerator.h"
#import "DFLoopOperation_SubclassingHooks.h"
#import "ExtNil.h"

@interface DFReactiveOperation ()

@property (strong, nonatomic) NSMutableDictionary *reactiveConnections;

@end

@implementation DFReactiveOperation

+ (instancetype)operationFromBlock:(id)block ports:(NSArray *)ports
{
    return [[[self class] alloc] initWithRetryBlock:block ports:ports];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _connectionCapacity = -1;
        _reactiveConnections = [NSMutableDictionary dictionary];
    }
    return self;
}

- (instancetype)clone:(NSMutableDictionary *)objToPointerMapping
{
    __block DFReactiveOperation *newReactiveOperation = nil;
    dispatch_block_t block = ^() {
        newReactiveOperation = [super clone:objToPointerMapping];
        [self.reactiveConnections enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            ReactiveConnectionInfo *info = obj;
            NSString *toProperty = key;
            NSString *fromProperty = info.connectedProperty;
            DFOperation *connectedOperation = info.operation;
            NSValue *pointerKey = [NSValue valueWithPointer:(__bridge const void *)(connectedOperation)];
            //check if object is already present
            DFOperation *operation = objToPointerMapping[pointerKey];
            if (!operation) {
                operation = [connectedOperation clone:objToPointerMapping];
                objToPointerMapping[pointerKey] = operation;
            }
            [newReactiveOperation addReactiveDependency:operation withBindings:@{toProperty : fromProperty}];
        }];
    };
    [self safelyExecuteBlock:block];
    return newReactiveOperation;
}

- (id)copyWithZone:(NSZone *)zone
{
    __block DFReactiveOperation *newReactiveOperation = nil;
    dispatch_block_t block = ^() {
        newReactiveOperation = [super copyWithZone:zone];
        [self.reactiveConnections enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            ReactiveConnectionInfo *info = obj;
            NSString *toProperty = key;
            NSString *fromProperty = info.connectedProperty;
            DFOperation *connectedOperation = info.operation;
            [newReactiveOperation addReactiveDependency:connectedOperation withBindings:@{toProperty : fromProperty}];
        }];
    };
    [self safelyExecuteBlock:block];
    return newReactiveOperation;
}

- (void)addPortToInputPorts:(NSString *)port
{
    if (![self.inputPorts containsObject:port]) {
        if (!self.inputPorts) {
            self.inputPorts = [NSArray arrayWithObject:port];
        }
        else {
            self.inputPorts = [self.inputPorts arrayByAddingObject:port];
        }
    }
    if ([self.inputPorts count] != [self.executionObj numberOfPorts]) {
        //update execution obj
        self.executionObj = [Execution_Class instanceForNumberOfArguments:[self.inputPorts count]];
    }
}

- (NSArray *)freePorts
{
    __block NSMutableArray *freePorts = nil;
    dispatch_block_t block = ^() {
        freePorts = [NSMutableArray arrayWithArray:[super freePorts]];
        [self.reactiveConnections enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            [freePorts removeObject:key];
        }];
    };
    [self safelyExecuteBlock:block];
    return freePorts;
}

- (ReactiveConnectionInfo *)newInfo
{
    return [ReactiveConnectionInfo new];
}

- (void)reactiveConnectionPropertyChanged:(id)changedValue property:(NSString *)property operation:(DFOperation *)operation
{
    if (self.state == OperationStateDone) {
        return;
    }
    id newInput = changedValue;
    //get new input and add it to an array of existing inputs
    if (!newInput) {
        newInput = [EXTNil null];
    }
    dispatch_block_t block = ^(void) {
        ReactiveConnectionInfo *info  = self.reactiveConnections[property];
        [info addInput:newInput];
        if ([self canExecute]) {
            if (![self next]) {
                [self done];
            }
        }
    };
    [self safelyExecuteBlock:block];
}

- (void)reactiveConnectionStateChanged:(id)changedValue property:(NSString *)property operation:(DFOperation *)operation
{
    if (self.state == OperationStateDone) {
        return;
    }
    dispatch_block_t block = ^(void) {
        ReactiveConnectionInfo *info  = [self.reactiveConnections objectForKey:property];
        info.operationState = [changedValue integerValue];
        if (self.state == OperationStateExecuting && [self isDone]) {
            [self done];
        }
    };
    [self safelyExecuteBlock:block];
}

- (NSDictionary *)addReactiveDependency:(DFOperation *)operation withBindings:(NSDictionary *)bindings
{
    __block NSDictionary *validBindings = nil;
    dispatch_queue_t observationQueue = [[self class] operationObservationHandlingQueue];
    //operation connected reactively is not a dependency
    dispatch_block_t block = ^(void) {
        NSSet *filteredKeys = [self validBindingsForOperation:operation bindings:bindings];
        [filteredKeys enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
            NSString *property = obj;
            NSString *connectedProperty = [bindings objectForKey:property];
            @weakify(self);
            //add observation for property change
            AMBlockToken *propertyObservationToken = [operation addObserverForKeyPath:connectedProperty task:^(id obj, NSDictionary *change) {
                DFOperation *connectedOperation = obj;
                dispatch_async(observationQueue, ^{
                    @strongify(self);
                    [self reactiveConnectionPropertyChanged:change[NSKeyValueChangeNewKey]
                                                   property:property
                                                  operation:connectedOperation];
                });
            }];
            
            //add observation for state change
            AMBlockToken *stateObservationToken = [operation addObserverForKeyPath:@keypath(operation.state) task:^(id obj, NSDictionary *change) {
                DFOperation *connectedOperation = obj;
                dispatch_async(observationQueue, ^{
                    @strongify(self);
                    [self reactiveConnectionStateChanged:change[NSKeyValueChangeNewKey]
                                                property:property
                                               operation:connectedOperation];
                });
            }];
            
            //create info for operation
            ReactiveConnectionInfo *info = [self newInfo];
            info.operation = operation;
            info.operationState = operation.state;
            info.stateObservationToken = stateObservationToken;
            info.propertyObservationToken = propertyObservationToken;
            info.connectedProperty = connectedProperty;
            info.connectionCapacity = self.connectionCapacity;
            //check operation input, to see if it has value
            if (operation.state == OperationStateExecuting || operation.state == OperationStateDone) {
                //make sure that property has been set otherwise we will be working with incorrect value.
                if ([operation isPropertySet:connectedProperty]) {
                    id input = [operation valueForKey:connectedProperty];
                    [info addInput:input];
                }
            }
            [self.reactiveConnections setObject:info forKey:property];
        }];
        validBindings = [bindings dictionaryWithValuesForKeys:[filteredKeys allObjects]];
    };
    [self safelyExecuteBlock:block];
    return validBindings;
}

- (BOOL)connectPortReactively:(NSString *)port toOutputOfOperation:(id<Operation>)operation
{
    if ([port length] > 0 && [self respondsToSelector:NSSelectorFromString(setterFromProperty(port))]) {
        NSDictionary *validBindings = [self addReactiveDependency:operation withBindings:@{port : @keypath(operation.output)}];
        return ([validBindings count] > 0);
    }
    return NO;
}

- (void)removeDependency:(NSOperation *)operation
{
    [super removeDependency:operation];
    dispatch_block_t block = ^(void) {
        if ([operation isKindOfClass:[DFOperation class]]) {
            //if operation is connected reactively
            NSMutableArray *connectionsToRemove = [NSMutableArray array];
            [self.reactiveConnections enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                ReactiveConnectionInfo *info = obj;
                if ([info.operation isEqual:operation]) {
                    [connectionsToRemove addObject:key];
                }
            }];
            [self.reactiveConnections removeObjectsForKeys:connectionsToRemove];
        }
    };
    [self safelyExecuteBlock:block];
}

- (void)setConnectionCapacity:(int)connectionCapacity
{
    dispatch_block_t block = ^(void) {
        if (connectionCapacity == _connectionCapacity) {
            return;
        }
        [self.reactiveConnections enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            ReactiveConnectionInfo *info = obj;
            info.connectionCapacity = connectionCapacity;
        }];
        _connectionCapacity = connectionCapacity;
    };
    [self safelyExecuteBlock:block];
}

- (void)generateNextValues
{
    [self.reactiveConnections enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        ReactiveConnectionInfo *info = obj;
        DFOperation *operation = info.operation;
        OperationState operationState = info.operationState;
        if ([operation isKindOfClass:[DFSequenceGenerator class]] &&
            (operationState == OperationStateExecuting) &&
            [info.inputs count] == 0) {
            @weakify(operation);
            dispatch_queue_t startQueue = [[self class] operationStartQueue];
            dispatch_async(startQueue, ^{
                @strongify(operation);
                DFSequenceGenerator *generator = (DFSequenceGenerator *)operation;
                [generator generateNext];
            });
        }
    }];
}

- (BOOL)next
{
    __block BOOL result = NO;
    dispatch_block_t block = ^(void) {
        result = [self retry];
        if (result) {
            [self generateNextValues];
        }
    };
    [self safelyExecuteBlock:block];
    return result;
}

- (BOOL)isReadyToExecute
{
    __block BOOL ready = YES;
    dispatch_block_t block = ^(void) {
        [self.reactiveConnections enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            ReactiveConnectionInfo *info = obj;
            OperationState state = info.operationState;
            //if there is no operation associated with
            ready = (state == OperationStateExecuting || state == OperationStateDone);
            if (ready) {
                NSMutableArray *inputValues = info.inputs;
                ready = ([inputValues count] > 0);
            }
            if (!ready) {
                *stop = YES;
            }
        }];
    };
    [self safelyExecuteBlock:block];
    return ready;
}

- (BOOL)canExecute
{
    __block BOOL result = NO;
    dispatch_block_t block = ^(void) {
        if (self.isExecuting && !self.isExecutingOperation) {
            result = [self isReadyToExecute];
        }
        else {
            result = NO;
        }
    };
    [self safelyExecuteBlock:block];
    return result;
}

- (BOOL)isDone
{
    __block BOOL result = NO;
    dispatch_block_t block = ^(void) {
        if (self.state == OperationStateDone) {
            result = YES;
        }
        else if (self.isExecuting && !self.isExecutingOperation) {
            __block BOOL done = (self.executionCount > 0);
            [self.reactiveConnections enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                ReactiveConnectionInfo *info = obj;
                done = NO;
                if ((info.operationState == OperationStateDone) && ([info.inputs count] == 0)) {
                    done = YES;
                    *stop = YES;
                }
            }];
            result = done;
        }
    };
    [self safelyExecuteBlock:block];
    return result;
}

- (NSArray *)connectedOperations
{
    __block NSArray *result = nil;
    dispatch_block_t block = ^(void) {
        NSArray *operations = [super connectedOperations];
        NSMutableSet *connectedOperations = [NSMutableSet set];
        if (operations) {
            [connectedOperations addObjectsFromArray:operations];
        }
        [self.reactiveConnections enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            ReactiveConnectionInfo *info = obj;
            DFOperation *connectedOperation = info.operation;
            if (connectedOperation) {
                [connectedOperations addObject:connectedOperation];
            }
        }];
        result = [connectedOperations allObjects];
    };
    [self safelyExecuteBlock:block];
    return result;
}

- (BOOL)hasReactiveBindings
{
    __block BOOL result = NO;
    dispatch_block_t block = ^(void) {
        result = ([self.reactiveConnections count] > 0);
    };
    [self safelyExecuteBlock:block];
    return result;
}

- (BOOL)isBindingReactive:(NSDictionary *)binding
{
    __block BOOL result = NO;
    NSString *outPort = [binding allValues][0];
    NSString *inPort = [binding allKeys][0];
    dispatch_block_t block = ^(void) {
        [self.reactiveConnections enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            ReactiveConnectionInfo *info = obj;
            NSString *connectionInPort = key;
            NSString *connectionOutPort = info.connectedProperty;
            if ([connectionInPort isEqualToString:inPort] && [connectionOutPort isEqualToString:outPort]) {
                result = YES;
                *stop = YES;
            }
        }];
    };
    [self safelyExecuteBlock:block];
    return result;
}

- (NSArray *)reactiveOperations
{
    __block NSMutableSet *operations = [NSMutableSet set];
    dispatch_block_t block = ^(void) {
        [self.reactiveConnections enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            ReactiveConnectionInfo *info = obj;
            [operations addObject:info.operation];
        }];
    };
    [self safelyExecuteBlock:block];
    return [operations allObjects];
}

- (NSDictionary *)reactiveBindingsForOperation:(DFOperation *)operation
{
    __block NSMutableDictionary *bindings = [NSMutableDictionary dictionary];
    dispatch_block_t block = ^(void) {
        [[self reactiveConnections] enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            ReactiveConnectionInfo *info = obj;
            DFOperation *connectedOperation = info.operation;
            if (connectedOperation == operation) {
                NSString *connectedToProperty = key;
                NSString *connectedFromProperty = info.connectedProperty;
                bindings[connectedToProperty] = connectedFromProperty;
            }
        }];
    };
    [self safelyExecuteBlock:block];
    return bindings;
}

- (NSDictionary *)bindingsForOperation:(DFOperation *)operation
{
    __block NSDictionary *result = nil;
    dispatch_block_t block = ^(void) {
    NSDictionary *bindings = [super bindingsForOperation:operation];
        NSDictionary *reactiveBindings = [self reactiveBindingsForOperation:operation];
        if (!bindings) {
            bindings = reactiveBindings;
        }
        else {
            [[bindings mutableCopy] addEntriesFromDictionary:reactiveBindings];
        }
        result = bindings;
    };
    [self safelyExecuteBlock:block];
    return result;
}

- (void)prepareExecutionObj:(Execution_Class *)executionObj
{
    dispatch_block_t block = ^(void) {
        [self.inputPorts enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSString *property = obj;
            ReactiveConnectionInfo *info = [self.reactiveConnections objectForKey:property];
            id value = nil;
            if (info) {
                //take the first input and assign
                value = info.inputs[0];
                [info.inputs removeObjectAtIndex:0];
            }
            else {
                value = [self valueForKey:property];
            }
             value = (value == [EXTNil null]) ? nil : value;
            [executionObj setValue:value atArgIndex:idx];
        }];
    };
    [self safelyExecuteBlock:block];
}

- (void)prepareOperation:(DFOperation *)operation
{
    dispatch_block_t block = ^(void) {
        if (self.retryBlock) {
            return;
        }
        NSDictionary *mapping = [[self class] freePortsToOperationMapping:operation];
        [self.inputPorts enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSString *property = obj;
            NSSet *operations = [mapping objectForKey:property];
            ReactiveConnectionInfo *info = self.reactiveConnections[property];
            id value = nil;
            if (info) {
                //take the first input and assign
                value = info.inputs[0];
                [info.inputs removeObjectAtIndex:0];
            }
            else {
                value = [self valueForKey:property];
            }
            value = (value == [EXTNil null]) ? nil : value;
            [operations enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
                DFOperation *operation = obj;
                [operation setValue:value forKey:property];
            }];
        }];
    };
    [self safelyExecuteBlock:block];
}

- (void)operation:(DFOperation *)operation stateChanged:(id)changedValue
{
    dispatch_block_t block = ^(void) {
        if ((self.state == OperationStateDone) || (operation.state != OperationStateDone)) {
            return;
        }
        [operation safelyRemoveObserverWithBlockToken:self.operationObservationToken];
        self.operationObservationToken = nil;
        self.error = operation.error;
        self.output = operation.output;
        self.executingOperation = nil;
        BOOL finished = NO;
        if ([self isDone]) {
            finished = YES;
        }
        else if ([self canExecute]) {
            finished = !([self next]);
        }
        if (finished) {
            [self done];
        }
    };
    [self safelyExecuteBlock:block];
}

- (id)valueForUndefinedKey:(NSString *)key
{
    __block id value = nil;
    dispatch_block_t block = ^(void) {
        ReactiveConnectionInfo *info = [self.reactiveConnections objectForKey:key];
        if (info) {
            value = [info.inputs lastObject];
        }
        else {
            value = [super valueForUndefinedKey:key];
        }
    };
    [self safelyExecuteBlock:block];
    return value;
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key
{
    dispatch_block_t block = ^(void) {
        ReactiveConnectionInfo *info = [self.reactiveConnections objectForKey:key];
        if (info) {
            [info.inputs addObject:(value ? value : [EXTNil null])];
        }
        else {
            [super setValue:value forUndefinedKey:key];
        }
    };
    [self safelyExecuteBlock:block];
}

- (void)setValueArray:(NSArray *)valueArray forKey:(NSString *)key
{
    dispatch_block_t block = ^(void) {
        ReactiveConnectionInfo *info = [self.reactiveConnections objectForKey:key];
        if (info) {
            [info.inputs addObjectsFromArray:valueArray];
        }
    };
    [self safelyExecuteBlock:block];
}

- (void)main
{
    dispatch_block_t block = ^(void) {
        if (self.state != OperationStateExecuting) {
            return;
        }
        if (self.error) {
            self.output = [DFVoidObject new];
            [self done];
        }
        else {
            [self generateNextValues];
            @weakify(self);
            dispatch_queue_t observationQueue = [[self class] operationObservationHandlingQueue];
            dispatch_async(observationQueue, ^{
                @strongify(self);
                if (!self) {
                    return;
                }
                dispatch_block_t block = ^(void) {
                    if ((self.state == OperationStateExecuting) && [self isDone]) {
                        self.output = [DFVoidObject new];
                        [self done];
                    }
                    else if ([self canExecute]) {
                        if (![self next]) {
                            self.output = [DFVoidObject new];
                            [self done];
                        }
                    }
                };
                [self safelyExecuteBlock:block];
            });
        }
    };
    [self safelyExecuteBlock:block];
}

- (void)done
{
    [super done];
    [self.reactiveConnections enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        ReactiveConnectionInfo *info = obj;
        [info clean];
    }];
}

@end