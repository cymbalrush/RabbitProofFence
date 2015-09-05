//
//  DFReactiveOperation.m

//
//  Created by Sinha, Gyanendra on 6/23/14.

//

#import "DFReactiveOperation.h"
#import "DFMetaOperation_SubclassingHooks.h"
#import "ReactiveConnection.h"
#import "DFGenerator.h"
#import "DFLoopOperation_SubclassingHooks.h"
#import "ExtNil.h"

@interface DFReactiveOperation ()

@property (strong, nonatomic) NSMutableDictionary *DF_reactiveConnections;

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
        _DF_reactiveConnections = [NSMutableDictionary dictionary];
        _hot = YES;
    }
    return self;
}

- (instancetype)DF_clone:(NSMutableDictionary *)objToPointerMapping
{
    __block DFReactiveOperation *newReactiveOperation = nil;
    dispatch_block_t block = ^() {
        newReactiveOperation = [super DF_clone:objToPointerMapping];
        [self.DF_reactiveConnections enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            ReactiveConnection *connection = obj;
            NSString *toProperty = key;
            NSString *fromProperty = connection.fromPort;
            DFOperation *connectedOperation = connection.operation;
            NSValue *pointerKey = [NSValue valueWithPointer:(__bridge const void *)(connectedOperation)];
            //check if object is already present
            DFOperation *operation = objToPointerMapping[pointerKey];
            if (!operation) {
                operation = [connectedOperation DF_clone:objToPointerMapping];
                objToPointerMapping[pointerKey] = operation;
            }
            [newReactiveOperation addReactiveDependency:operation withBindings:@{toProperty : fromProperty}];
        }];
    };
    [self DF_safelyExecuteBlock:block];
    return newReactiveOperation;
}

- (id)copyWithZone:(NSZone *)zone
{
    __block DFReactiveOperation *newReactiveOperation = nil;
    dispatch_block_t block = ^() {
        newReactiveOperation = [super copyWithZone:zone];
        [self.DF_reactiveConnections enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            ReactiveConnection *connection = obj;
            NSString *toProperty = key;
            NSString *fromProperty = connection.fromPort;
            DFOperation *connectedOperation = connection.operation;
            [newReactiveOperation addReactiveDependency:connectedOperation withBindings:@{toProperty : fromProperty}];
        }];
    };
    [self DF_safelyExecuteBlock:block];
    return newReactiveOperation;
}

- (void)DF_addPortToInputPorts:(NSString *)port
{
    if (![self.DF_inputPorts containsObject:port]) {
        if (!self.DF_inputPorts) {
            self.DF_inputPorts = [NSArray arrayWithObject:port];
        }
        else {
            self.DF_inputPorts = [self.DF_inputPorts arrayByAddingObject:port];
        }
    }
    if ([self.DF_inputPorts count] != [self.DF_executionObj numberOfPorts]) {
        //update execution obj
        self.DF_executionObj = [Execution_Class instanceForNumberOfArguments:[self.DF_inputPorts count]];
    }
}

- (NSArray *)freePorts
{
    __block NSMutableArray *freePorts = nil;
    dispatch_block_t block = ^() {
        freePorts = [NSMutableArray arrayWithArray:[super freePorts]];
        [self.DF_reactiveConnections enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            ReactiveConnection *connection = obj;
            [freePorts removeObject:connection.toPort];
        }];
    };
    [self DF_safelyExecuteBlock:block];
    return freePorts;
}

- (NSDictionary *)connections
{
    NSMutableDictionary *result = [[super connections] mutableCopy];
    [result addEntriesFromDictionary:self.DF_reactiveConnections];
    return result;
}

- (ReactiveConnection *)DF_newReactiveConnection
{
    return [ReactiveConnection new];
}

- (void)DF_reactiveConnectionPropertyChanged:(id)changedValue
                                    property:(NSString *)property
                                   operation:(DFOperation *)operation
{
    if (self.DF_state == OperationStateDone) {
        return;
    }
    id newInput = changedValue;
    //get new input and add it to an array of existing inputs
    if (!newInput) {
        newInput = [EXTNil null];
    }
    dispatch_block_t block = ^(void) {
        ReactiveConnection *connection  = self.DF_reactiveConnections[property];
        [connection addInput:newInput];
        if ([self DF_canExecute]) {
            if (![self DF_next]) {
                [self DF_done];
            }
        }
    };
    [self DF_safelyExecuteBlock:block];
}

- (void)DF_reactiveConnectionStateChanged:(id)changedValue property:(NSString *)property operation:(DFOperation *)operation
{
    if (self.DF_state == OperationStateDone) {
        return;
    }
    dispatch_block_t block = ^(void) {
        ReactiveConnection *connection  = self.DF_reactiveConnections[property];
        connection.operationState = [changedValue integerValue];
        if (self.DF_state == OperationStateExecuting && [self DF_isDone]) {
            [self DF_done];
        }
    };
    [self DF_safelyExecuteBlock:block];
}

- (NSDictionary *)addReactiveDependency:(DFOperation *)operation withBindings:(NSDictionary *)bindings
{
    if (!operation || operation == self) {
        return nil;
    }
    __block NSDictionary *validBindings = nil;
    dispatch_queue_t observationQueue = [[self class] DF_observationQueue];
    //operation connected reactively is not a dependency
    dispatch_block_t block = ^(void) {
        NSSet *filteredKeys = [self DF_validBindingsForOperation:operation bindings:bindings];
        [filteredKeys enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
            NSString *toPort = obj;
            NSString *fromPort = bindings[toPort];
            @weakify(self);
            //add observation for property change
            AMBlockToken *propertyObservationToken = [operation addObserverForKeyPath:fromPort task:^(id obj, NSDictionary *change) {
                DFOperation *connectedOperation = obj;
                dispatch_async(observationQueue, ^{
                    @strongify(self);
                    [self DF_reactiveConnectionPropertyChanged:change[NSKeyValueChangeNewKey]
                                                     property:toPort
                                                    operation:connectedOperation];
                });
            }];
            
            //add observation for state change
            AMBlockToken *stateObservationToken = [operation addObserverForKeyPath:@keypath(operation.DF_state) task:^(id obj, NSDictionary *change) {
                DFOperation *connectedOperation = obj;
                dispatch_async(observationQueue, ^{
                    @strongify(self);
                    [self DF_reactiveConnectionStateChanged:change[NSKeyValueChangeNewKey]
                                                  property:toPort
                                                 operation:connectedOperation];
                });
            }];
            
            //create info for operation
            ReactiveConnection *connection = [self DF_newReactiveConnection];
            connection.operation = operation;
            connection.operationState = operation.DF_state;
            connection.stateObservationToken = stateObservationToken;
            connection.propertyObservationToken = propertyObservationToken;
            connection.fromPort = fromPort;
            connection.toPort = toPort;
            connection.connectionCapacity = self.connectionCapacity;
            Class portType = [self portType:toPort];
            //infer type
            if (!portType || portType == [EXTNil null]) {
                portType = [operation portType:fromPort];
            }
            connection.inferredType = portType;
            //check operation input, to see if it has value
            if (operation.DF_state == OperationStateExecuting || operation.DF_state == OperationStateDone) {
                //make sure that property has been set otherwise we will be working with incorrect value.
                if ([operation DF_isPropertySet:fromPort]) {
                    id input = [operation valueForKey:fromPort];
                    [connection addInput:input];
                }
            }
            self.DF_reactiveConnections[toPort] = connection;
        }];
        validBindings = [bindings dictionaryWithValuesForKeys:[filteredKeys allObjects]];
    };
    [self DF_safelyExecuteBlock:block];
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
            [self.DF_reactiveConnections enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                ReactiveConnection *connection = obj;
                if ([connection.operation isEqual:operation]) {
                    [connectionsToRemove addObject:key];
                }
            }];
            [self.DF_reactiveConnections removeObjectsForKeys:connectionsToRemove];
        }
    };
    [self DF_safelyExecuteBlock:block];
}

- (void)setConnectionCapacity:(int)connectionCapacity
{
    dispatch_block_t block = ^(void) {
        if (connectionCapacity == _connectionCapacity) {
            return;
        }
        [self.DF_reactiveConnections enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            ReactiveConnection *connection = obj;
            connection.connectionCapacity = connectionCapacity;
        }];
        _connectionCapacity = connectionCapacity;
    };
    [self DF_safelyExecuteBlock:block];
}

- (void)DF_generateNextValues
{
    [self.DF_reactiveConnections enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        ReactiveConnection *connection = obj;
        DFOperation *operation = connection.operation;
        OperationState operationState = connection.operationState;
        if ([operation isKindOfClass:[DFGenerator class]] &&
            (operationState == OperationStateExecuting) &&
            connection.inputs.count == 0) {
            @weakify(operation);
            dispatch_queue_t startQueue = [[self class] DF_startQueue];
            dispatch_async(startQueue, ^{
                @strongify(operation);
                DFGenerator *generator = (DFGenerator *)operation;
                [generator next];
            });
        }
    }];
}

- (BOOL)DF_next
{
    BOOL result = [super DF_next];
    if (result) {
        [self DF_generateNextValues];
    }
    return result;
}

- (BOOL)DF_isReadyToExecute
{
    __block BOOL ready = (self.DF_executionCount == 0);
    [self.DF_reactiveConnections enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        ReactiveConnection *connection = obj;
        OperationState state = connection.operationState;
        //if there is no operation associated with
        ready = (state == OperationStateExecuting || state == OperationStateDone);
        if (ready) {
            NSMutableArray *inputValues = connection.inputs;
            ready = (inputValues.count > 0);
        }
        if (!ready) {
            *stop = YES;
        }
    }];
    return ready;
}

- (BOOL)DF_canExecute
{
    BOOL result = NO;
    if (self.isExecuting && !self.DF_isExecutingOperation) {
        result = [self DF_isReadyToExecute];
    }
    return result;
}

- (BOOL)DF_isDone
{
    BOOL result = NO;
    if (self.DF_state == OperationStateDone) {
        result = YES;
    }
    else if (self.isExecuting && !self.DF_isExecutingOperation) {
        __block BOOL done = (self.DF_executionCount > 0);
        [self.DF_reactiveConnections enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            ReactiveConnection *connection = obj;
            done = NO;
            if ((connection.operationState == OperationStateDone) && (connection.inputs.count == 0)) {
                done = YES;
                *stop = YES;
            }
        }];
        result = done;
    }
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
        [self.DF_reactiveConnections enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            ReactiveConnection *connection = obj;
            DFOperation *connectedOperation = connection.operation;
            if (connectedOperation) {
                [connectedOperations addObject:connectedOperation];
            }
        }];
        result = [connectedOperations allObjects];
    };
    [self DF_safelyExecuteBlock:block];
    return result;
}

- (BOOL)DF_hasReactiveBindings
{
    return ([self.DF_reactiveConnections count] > 0);
}

- (BOOL)isBindingReactive:(NSDictionary *)binding
{
    __block BOOL result = NO;
    NSString *outPort = [binding allValues][0];
    NSString *inPort = [binding allKeys][0];
    dispatch_block_t block = ^(void) {
        [self.DF_reactiveConnections enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            ReactiveConnection *connection = obj;
            NSString *connectionInPort = key;
            NSString *connectionOutPort = connection.fromPort;
            if ([connectionInPort isEqualToString:inPort] && [connectionOutPort isEqualToString:outPort]) {
                result = YES;
                *stop = YES;
            }
        }];
    };
    [self DF_safelyExecuteBlock:block];
    return result;
}

- (NSArray *)DF_operationsConnectedReactively
{
    __block NSMutableSet *operations = [NSMutableSet set];
    [self.DF_reactiveConnections enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        ReactiveConnection *connection = obj;
        [operations addObject:connection.operation];
    }];
    return [operations allObjects];
}

- (NSDictionary *)DF_reactiveBindingsForOperation:(DFOperation *)operation
{
    __block NSMutableDictionary *bindings = [NSMutableDictionary dictionary];
    [self.DF_reactiveConnections enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        ReactiveConnection *connection = obj;
        DFOperation *connectedOperation = connection.operation;
        if (connectedOperation == operation) {
            NSString *connectedToProperty = key;
            NSString *connectedFromProperty = connection.fromPort;
            bindings[connectedToProperty] = connectedFromProperty;
        }
    }];
    return bindings;
}

- (NSDictionary *)bindingsForOperation:(DFOperation *)operation
{
    __block NSDictionary *result = nil;
    dispatch_block_t block = ^(void) {
        NSDictionary *bindings = [super bindingsForOperation:operation];
        NSDictionary *reactiveBindings = [self DF_reactiveBindingsForOperation:operation];
        if (!bindings) {
            bindings = reactiveBindings;
        }
        else {
            NSMutableDictionary *dict = [bindings mutableCopy];
            [dict addEntriesFromDictionary:reactiveBindings];
            bindings = dict;
        }
        result = bindings;
    };
    [self DF_safelyExecuteBlock:block];
    return result;
}

- (void)DF_prepareExecutionObj:(Execution_Class *)executionObj
{
    [self.DF_inputPorts enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSString *port = obj;
        ReactiveConnection *connection = self.DF_reactiveConnections[port];
        id value = nil;
        if (connection) {
            //take the first input and assign
            value = connection.inputs[0];
            [connection.inputs removeObjectAtIndex:0];
        }
        else {
            value = [self valueForKey:port];
        }
        value = (value == [EXTNil null] ? nil : value);
        [executionObj setValue:value atArgIndex:idx];
    }];
}

- (void)DF_prepareOperation:(DFOperation *)operation
{
    if (self.retryBlock) {
        return;
    }
    NSDictionary *mapping = [[self class] DF_freePortsToOperationMapping:operation];
    [self.DF_inputPorts enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSString *port = obj;
        NSSet *operations = mapping[port];
        ReactiveConnection *connection = self.DF_reactiveConnections[port];
        id value = nil;
        if (connection) {
            //take the first input and assign
            value = connection.inputs[0];
            [connection.inputs removeObjectAtIndex:0];
        }
        else {
            value = [self valueForKey:port];
        }
        value = (value == [EXTNil null] ? nil : value);
        [operations enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
            DFOperation *operation = obj;
            [operation setValue:value forKey:port];
        }];
    }];
}

- (void)DF_operation:(DFOperation *)operation stateChanged:(id)changedValue
{
    dispatch_block_t block = ^(void) {
        OperationState state = [changedValue integerValue];
        if ((self.DF_state == OperationStateDone) || (state != OperationStateDone)) {
            return;
        }
        self.DF_error = operation.DF_error;
        self.DF_output = operation.DF_output;
        self.DF_runningOperationInfo = nil;
        BOOL finished = NO;
        if ([self DF_isDone]) {
            finished = YES;
        }
        else if ([self DF_canExecute]) {
            finished = !([self DF_next]);
        }
        if (finished) {
            [self DF_done];
        }
    };
    [self DF_safelyExecuteBlock:block];
}

- (id)valueForUndefinedKey:(NSString *)key
{
    __block id value = nil;
    dispatch_block_t block = ^(void) {
        ReactiveConnection *connection = self.DF_reactiveConnections[key];
        if (connection) {
            value = [connection.inputs firstObject];
        }
        else {
            value = [super valueForUndefinedKey:key];
        }
    };
    [self DF_safelyExecuteBlock:block];
    return value;
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key
{
    dispatch_block_t block = ^(void) {
        ReactiveConnection *info = self.DF_reactiveConnections[key];
        if (info) {
            [info addInput:value];
        }
        else {
            [super setValue:value forUndefinedKey:key];
        }
    };
    [self DF_safelyExecuteBlock:block];
}

- (void)setValueArray:(NSArray *)valueArray forKey:(NSString *)key
{
    dispatch_block_t block = ^(void) {
        ReactiveConnection *info = [self.DF_reactiveConnections objectForKey:key];
        if (info) {
            [info.inputs addObjectsFromArray:valueArray];
        }
    };
    [self DF_safelyExecuteBlock:block];
}

- (void)main
{
    dispatch_block_t block = ^(void) {
        if (self.DF_state != OperationStateExecuting) {
            return;
        }
        else {
            [self DF_generateNextValues];
            @weakify(self);
            dispatch_queue_t observationQueue = [[self class] DF_observationQueue];
            dispatch_async(observationQueue, ^{
                @strongify(self);
                if (!self) {
                    return;
                }
                dispatch_block_t block = ^(void) {
                    if ((self.DF_state == OperationStateExecuting) && [self DF_isDone]) {
                        [self DF_done];
                    }
                    else if ([self DF_canExecute]) {
                        if (![self DF_next]) {
                            [self DF_done];
                        }
                    }
                };
                [self DF_safelyExecuteBlock:block];
            });
        }
    };
    [self DF_safelyExecuteBlock:block];
}

- (void)DF_done
{
    [super DF_done];
    [self.DF_reactiveConnections enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        ReactiveConnection *info = obj;
        [info clean];
    }];
}

@end