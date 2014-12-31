//
//  DFOperation.m
//  vf-hollywood
//
//  Created by Sinha, Gyanendra on 6/23/14.
//  Copyright (c) 2014 Conde Nast. All rights reserved.
//

#import "DFOperation.h"
#import "BlockDescription.h"
#import "Execution_Class.h"
#import "DependentOperationInfo.h"
#import "NSObject+BlockObservation.h"
#import "EXTScope.h"
#import "EXTKeyPathCoding.h"
#import <libkern/OSAtomic.h>
#import "DFVoidObject.h"
#import "EXTNil.h"

NSString * const DFOperationExceptionInvalidBlockSignature = @"DFOperationExceptionInvalidBlockSignature";
NSString * const DFOperationExceptionDuplicatePropertyNames = @"DFOperationExceptionDuplicatePropertyNames";
NSString * const DFOperationExceptionHandlerDomain = @"DFOperationExceptionHandlerDomain";
NSString * const DFOperationExceptionReason = @"DFOperationExceptionReason";
NSString * const DFOperationExceptionUserInfo = @"DFOperationExceptionUserInfo";
NSString * const DFOperationExceptionName = @"DFOperationException";
NSString * const DFOperationExceptionInEqualInputPorts = @"DFOperationOperationExceptionInEqualInputPorts";
NSString * const DFOperationExceptionInvalidInitialization = @"DFOperationExceptionInvalidInitialization";
NSString * const DFOperationExceptionMethodNotSupported = @"DFOperationExceptionMethodNotSupported";
NSString * const DFOperationExceptionIncorrectParameter = @"DFOperationExceptionIncorrectParameter";
const int DFOperationExceptionEncounteredErrorCode = 1000;

static char const * const OPERATION_SYNC_QUEUE = "com.operations.operationsSyncQueue";
static char const * const OPERATION_START_QUEUE = "com.operations.operationsStartQueue";
static char const * const OPERATION_OBSERVATION_HANDLING_QUEUE = "com.operations.operationObservationHandlingQueue";

NSArray *portNamesFromBlockArgs(const char *blockBody)
{
    if (blockBody != NULL) {
        NSString *body = [NSString stringWithUTF8String:blockBody];
        NSScanner *scanner = [NSScanner scannerWithString:body];
        [scanner setCaseSensitive:NO];
        [scanner scanUpToString:@"^" intoString:nil];
        BOOL found = [scanner scanUpToString:@"(" intoString:nil];
        NSString *args = nil;
        found &= [scanner scanUpToString:@")" intoString:&args];
        if (found && [args length] > 0) {
            args = [args substringWithRange:NSMakeRange(1, [args length] - 1)];
            NSArray *parameters = [args componentsSeparatedByString:@","];
            NSMutableArray *properties = [NSMutableArray array];
            [parameters enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                NSString *argBody = obj;
                argBody = [argBody stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                if ([argBody length] > 0) {
                    NSArray *params = [argBody componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                    if ([params count] < 2) {
                        @throw [NSException exceptionWithName:DFOperationExceptionName reason:@"Bad block body" userInfo:nil];
                    }
                    NSCharacterSet *charSet = [NSCharacterSet characterSetWithCharactersInString:@"*&"];
                    [properties addObject:[[params lastObject] stringByTrimmingCharactersInSet:charSet]];
                }
            }];
            return properties;
        }
    }
    return @[];
}

NSError * NSErrorFromException(NSException *exception)
{
    NSMutableDictionary * info = [NSMutableDictionary dictionary];
    [info setValue:exception.name forKey:DFOperationExceptionName];
    [info setValue:exception.reason forKey:DFOperationExceptionReason];
    [info setValue:exception.userInfo forKey:DFOperationExceptionUserInfo];
    return [[NSError alloc] initWithDomain:DFOperationExceptionHandlerDomain
                                      code:DFOperationExceptionEncounteredErrorCode
                                  userInfo:info];
}

NSString *setterFromProperty(NSString *property)
{
    if ([property length] == 0) {
        return @"";
    }
    return [NSString stringWithFormat:@"set%@%@:",  [[property substringToIndex:1] uppercaseString], [property substringFromIndex:1]];
}

@interface DFOperation ()

@property (assign, nonatomic) OperationState state;

@property (strong, nonatomic) NSError *error;

@property (strong, nonatomic) id output;

@property (strong, nonatomic) NSMutableArray *operationBindings;

@property (strong, nonatomic) NSMutableDictionary *propertySet;

@property (strong, nonatomic) AMBlockToken *isFinishedObservationToken_;

@property (strong, nonatomic) AMBlockToken *isReadyObservationToken_;

@property (assign, nonatomic) volatile OSSpinLock stateLock;

@property (strong, nonatomic) NSRecursiveLock *operationLock;

@property (strong, nonatomic) Execution_Class *executionObj;

@property (assign, nonatomic) BOOL isSuspended;

@property (strong, nonatomic) NSMutableSet *propertiesSet;

@property (strong, nonatomic) NSArray *inputPorts;

@property (assign, nonatomic) BOOL operationQueued;

@property (strong, nonatomic) NSMutableSet *execludedPorts;

@property (strong, nonatomic) NSMutableArray *outputConnections;

- (void)safelyRemoveObserverWithBlockToken:(AMBlockToken *)token;

@end

@implementation DFOperation

+ (Execution_Class *)executionObjFromBlock:(id)block
{
    BlockDescription *blockDesc = [[BlockDescription alloc] initWithBlock:block];
    NSMethodSignature  *sig = blockDesc.blockSignature;
    NSUInteger n = [sig numberOfArguments];
    //check for duplicate property name
    if ([sig methodReturnLength] == 0 || [sig methodReturnType][0] != @encode(id)[0]) {
        NSString *reason = [NSString stringWithFormat:@"Block needs to return object type"];
        @throw [NSException exceptionWithName:DFOperationExceptionInvalidBlockSignature reason:reason userInfo:nil];
    }
    for (int i = 1; i < [sig numberOfArguments]; i++) {
        if ([sig getArgumentTypeAtIndex:i][0] != @encode(id)[0]) {
            NSString *reason = [NSString stringWithFormat:@"Block needs object type at argument %d", (i - 1)];
            @throw [NSException exceptionWithName:DFOperationExceptionInvalidBlockSignature reason:reason userInfo:nil];
        }
    }
    Execution_Class *executionObj = [Execution_Class instanceForNumberOfArguments:(n - 1)];
    return executionObj;
}

//mapping between NSOperation properties and state
+ (NSString *)propertyKeyFromState:(OperationState)state
{
    DFOperation *operation = nil;
    NSString *propertyName = nil;
    switch (state) {
        case OperationStateReady: {
            propertyName = @keypath(operation.isReady);
            break;
        }
        case OperationStateExecuting: {
            propertyName = @keypath(operation.isExecuting);
            break;
        }
        case OperationStateDone: {
            propertyName = @keypath(operation.isFinished);
            break;
        }
        default: {
            break;
        }
    }
    return propertyName;
}

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key
{
    DFOperation *operation = nil;
    //state change is handled manually
    return [key isEqualToString:@keypath(operation.state)] ? NO : [super automaticallyNotifiesObserversForKey:key];
}

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key
{
    DFOperation *operation = nil;
    NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
    if ([key isEqualToString:@keypath(operation.isReady)]) {
        NSSet *properties = [NSSet setWithObject:@keypath(operation.isSuspended)];
        keyPaths = [keyPaths setByAddingObjectsFromSet:properties];
    }
    return keyPaths;
}

static inline BOOL StateTransitionIsValid(OperationState fromState, OperationState toState, BOOL isCancelled) {
    switch (fromState) {
        case OperationStateReady: {
            switch (toState) {
                case OperationStateExecuting: {
                    return YES;
                }
                case OperationStateDone: {
                    return isCancelled;
                }
                default: {
                    return NO;
                }
            }
            break;
        }
        case OperationStateExecuting: {
            switch (toState) {
                case OperationStateDone: {
                    return YES;
                }
                default: {
                    return NO;
                }
            }
            break;
        }
        case OperationStateDone: {
            return NO;
        }
        default: {
            return YES;
        }
    }
}

+ (dispatch_queue_t)syncQueue
{
    static dispatch_queue_t queue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create(OPERATION_SYNC_QUEUE, DISPATCH_QUEUE_SERIAL);
    });
    return queue;
}

+ (dispatch_queue_t)operationStartQueue
{
    static dispatch_queue_t queue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create(OPERATION_START_QUEUE, DISPATCH_QUEUE_SERIAL);
    });
    return queue;
}

+ (dispatch_queue_t)operationObservationHandlingQueue
{
    static dispatch_queue_t queue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create(OPERATION_OBSERVATION_HANDLING_QUEUE, DISPATCH_QUEUE_SERIAL);
    });
    return queue;
}

+ (NSMutableDictionary *)dependentOperations
{
    static NSMutableDictionary *operations = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        operations = [NSMutableDictionary dictionary];
    });
    return operations;
}

+ (NSMutableSet *)executingOperations
{
    static NSMutableSet *operations = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        operations = [NSMutableSet set];
    });
    return operations;
}

+ (void)startOperation:(DFOperation *)operation
{
    // prepare and start it
    dispatch_async([DFOperation operationStartQueue], ^{
        if (operation.state == OperationStateReady) {
            [operation start];
        }
    });
}

+ (void)removeObservations:(DFOperation *)operation
{
    //remove state observation
    AMBlockToken *observationToken = operation.isFinishedObservationToken_;
    [operation safelyRemoveObserverWithBlockToken:observationToken];
    operation.isFinishedObservationToken_ = nil;
    
    observationToken = operation.isReadyObservationToken_;
    [operation safelyRemoveObserverWithBlockToken:observationToken];
    operation.isReadyObservationToken_ = nil;
}

+ (void)cleanupOperation:(DFOperation *)finishedOperation
{
    NSValue *key = [NSValue valueWithPointer:(__bridge const void *)(finishedOperation)];
    NSMutableDictionary *mapping = [DFOperation dependentOperations];
    [[finishedOperation class] removeObservations:finishedOperation];
    NSArray *keys = [mapping allKeys];
    [keys enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSValue *key = obj;
        NSMutableSet *operations = mapping[key];
        [operations removeObject:finishedOperation];
        if (operations.count == 0) {
            [mapping removeObjectForKey:key];
        }
    }];
    [mapping removeObjectForKey:key];
}

+ (void)startDependentOperations:(DFOperation *)finishedOperation
{
    NSValue *key = [NSValue valueWithPointer:(__bridge const void *)(finishedOperation)];
    NSMutableDictionary *mapping = [DFOperation dependentOperations];
    __block NSMutableSet *operationsToStart = nil;
    NSMutableSet *dependentOperations = mapping[key];
    [dependentOperations enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        //find out dependent operation
        DFOperation *dependentOperation = obj;
        if (dependentOperation == finishedOperation) {
            return;
        }
        if (!dependentOperation.queue && (dependentOperation.state == OperationStateReady)) {
            NSArray *dependencies = dependentOperation.dependencies;
            __block BOOL isResolved = YES;
            //check if all dependencies are finished
            [dependencies enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                DFOperation *operation = obj;
                if (!operation.isFinished) {
                    isResolved = NO;
                    *stop = YES;
                }
            }];
            //if all dependencies are done then add it
            if (isResolved) {
                if (!operationsToStart) {
                    operationsToStart = [NSMutableSet new];
                }
                [operationsToStart addObject:dependentOperation];
            }
        }
    }];
    [self cleanupOperation:finishedOperation];
    if (operationsToStart.count > 0) {
        [operationsToStart enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
            DFOperation *operation = obj;
            [[operation class] startOperation:operation];
        }];
    }
}

+ (void)startObservingOperation:(DFOperation *)operation
{
    if (!operation) {
        return;
    }
    dispatch_sync([DFOperation syncQueue], ^{
        [[DFOperation executingOperations] addObject:operation];
        @weakify(operation);
        //add internal observer for isFinished
        AMBlockToken *observationToken = [operation addObserverForKeyPath:@keypath(operation.isFinished) task:^(id obj, NSDictionary *change) {
                dispatch_async([DFOperation syncQueue], ^{
                    @strongify(operation);
                    if (!operation) {
                        return;
                    }
                    [[operation class] startDependentOperations:operation];
                    [[DFOperation executingOperations] removeObject:operation];
                });
        }];
        operation.isFinishedObservationToken_ = observationToken;
        //if there is no queue, add internal observer for isReady
        if (!operation.queue) {
            if (operation.isReady) {
                [[operation class] startOperation:operation];
            }
            else {
                observationToken = [operation addObserverForKeyPath:@keypath(operation.isReady) task:^(id obj, NSDictionary *change) {
                    //check operation state
                    if ([[change valueForKey:NSKeyValueChangeNewKey] boolValue]) {
                        //move it to the same queue
                        dispatch_async([DFOperation syncQueue], ^{
                            @strongify(operation);
                            if (!operation) {
                                return;
                            }
                            AMBlockToken *observationToken = operation.isReadyObservationToken_;
                            [operation safelyRemoveObserverWithBlockToken:observationToken];
                            operation.isReadyObservationToken_ = nil;
                            //make sure that operation can be executed
                            [[operation class] startOperation:operation];
                        });
                    }
                }];
                operation.isReadyObservationToken_ = observationToken;
            }
        }
        NSArray *dependencies = operation.dependencies;
        if ([dependencies count] > 0) {
            NSMutableDictionary *mapping = [DFOperation dependentOperations];
            [dependencies enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                DFOperation *dependentOperation = obj;
                NSValue *key = [NSValue valueWithPointer:(__bridge const void *)(dependentOperation)];
                NSMutableSet *dependentOperations = mapping[key];
                if (!dependentOperations) {
                    dependentOperations = [NSMutableSet set];
                    mapping[key] = dependentOperations;
                }
                [dependentOperations addObject:operation];
            }];
        }
    });
}

+ (instancetype)operationFromBlock:(id)block ports:(NSArray *)ports
{
    DFOperation *operation = [[[self class] alloc] init];
    operation.inputPorts = [ports copy];
    operation.executionBlock = block;
    return operation;
}

+ (Execution_Class *)executionObjectFromMethodSig:(NSMethodSignature *)sig
{
    NSUInteger n = [sig numberOfArguments];
    for (int i = 0; i < n ; i ++) {
        const char *encoding = [sig getArgumentTypeAtIndex:i];
        if (encoding[0] != @encode(id)[0]) {
            //throw an exception
            NSString *reason = [NSString stringWithFormat:@"Expects an object type at index [%d]", i];
            @throw [NSException exceptionWithName:DFOperationExceptionInvalidBlockSignature reason:reason userInfo:nil];
        }
    }
    Execution_Class *executionObj = [Execution_Class instanceForNumberOfArguments:(n - 1)];
    return executionObj;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _stateLock = OS_SPINLOCK_INIT;
        _operationLock = [NSRecursiveLock new];
        _operationBindings = [NSMutableArray new];
        _propertiesSet = [NSMutableSet new];
        _outputConnections = [NSMutableArray array];
        _queue = [[self class] operationQueue];
        _execludedPorts = [NSMutableSet setWithObject:@keypath(self.selfRef)];
    }
    return self;
}

- (void)setExecutionBlock:(id)executionBlock
{
    if (self.executionObj.executionBlock != executionBlock) {
        Execution_Class *executionObj = [DFOperation executionObjFromBlock:executionBlock];
        NSArray *ports = self.inputPorts;
        NSUInteger n = [executionObj numberOfPorts];
        if ((n > 0) && !([ports count] == n && [[NSSet setWithArray:ports] count] == [ports count])) {
            //throw an exception
            NSString *reason = [NSString stringWithFormat:@"Duplicate property names, make sure that property names are unique"];
            @throw [NSException exceptionWithName:DFOperationExceptionDuplicatePropertyNames reason:reason userInfo:nil];
        }
        self.executionObj = executionObj;
        self.executionObj.executionBlock = executionBlock;
    }
}

- (void)setState:(OperationState)state
{
    OSSpinLockLock(&_stateLock);
    if (_state == state) {
        OSSpinLockUnlock(&_stateLock);
        return;
    }
    if (StateTransitionIsValid(_state, state, self.isCancelled)) {
        NSString *oldStateKey = [DFOperation propertyKeyFromState:_state];
        NSString *newStateKey = [DFOperation propertyKeyFromState:state];
        [self willChangeValueForKey:oldStateKey];
        [self willChangeValueForKey:newStateKey];
        [self willChangeValueForKey:@keypath(self,state)];
        _state = state;
        [self didChangeValueForKey:@keypath(self,state)];
        [self didChangeValueForKey:newStateKey];
        [self didChangeValueForKey:oldStateKey];
    }
    OSSpinLockUnlock(&_stateLock);
}

- (void)setOutput:(id)output
{
    _output = output;
    [self.outputConnections enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSArray *array = obj;
        NSString *property = array[0];
        NSObject *object = array[1];
        dispatch_queue_t queue = array[2];
        if ([queue isEqual:[NSNull null]]) {
            [object setValue:output forKey:property];
        }
        else {
            dispatch_async(queue, ^{
                [object setValue:output forKey:property];
            });
        }
    }];
}

- (void)cancelRecursively
{
    [self cancel];
    [self.connectedOperations enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        DFOperation *operation = obj;
        if ([operation isKindOfClass:[DFOperation class]]) {
            [operation cancelRecursively];
        }
        else {
            [operation cancel];
        }
    }];
}

+ (void)copyExcludedPortValuesFromOperation:(DFOperation *)fromOperation
                             toOperation:(DFOperation *)toOperation
                           excludedPorts:(NSSet *)excludedPorts
{
    [excludedPorts enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        NSString *boundPort = obj;
        if ([fromOperation respondsToSelector:NSSelectorFromString(boundPort)] &&
            [toOperation respondsToSelector:NSSelectorFromString(setterFromProperty(boundPort))]) {
            id value = [fromOperation valueForKey:boundPort];
            [toOperation setValue:value forKey:boundPort];
        }
    }];
}

- (instancetype)copyWithZone:(NSZone *)zone
{
    __block DFOperation *operation = nil;
    dispatch_block_t block = ^(void) {
        [self breakRefCycleForExecutionObj:self.executionObj];
        operation = [[[self class] allocWithZone:zone] init];
        operation.executionObj = [self.executionObj copyWithZone:zone];
        operation.inputPorts = [self.inputPorts copyWithZone:zone];
        operation.queue = self.queue;
        operation.queuePriority = self.queuePriority;
        NSMutableSet *excludedPorts = [self.execludedPorts copy];
        operation.execludedPorts = excludedPorts;
        //copy excluded port values
        [[self class] copyExcludedPortValuesFromOperation:self toOperation:operation excludedPorts:excludedPorts];
        //copy it
        [self.dependencies enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            DFOperation *connectedOperation = obj;
            NSDictionary *bindings = [self bindingsForOperation:operation];
            if (bindings) {
                [operation addDependency:connectedOperation withBindings:bindings];
            }
            else {
                [operation addDependency:connectedOperation];
            }
        }];
        [operation.propertiesSet removeAllObjects];
    };
    [self safelyExecuteBlock:block];
    return operation;
}

- (instancetype)clone:(NSMutableDictionary *)objToPointerMapping
{
    __block DFOperation *operation = nil;
    dispatch_block_t block = ^(void) {
        [self breakRefCycleForExecutionObj:self.executionObj];
        operation = [[[self class] alloc] init];
        operation.executionObj = [self.executionObj copy];
        operation.inputPorts = [self.inputPorts copy];
        operation.queue = self.queue;
        operation.queuePriority = self.queuePriority;
        NSMutableSet *excludedPorts = [self.execludedPorts copy];
        operation.execludedPorts = excludedPorts;
        //copy excluded port values
        [[self class] copyExcludedPortValuesFromOperation:self toOperation:operation excludedPorts:excludedPorts];
        //copy it
        [self.dependencies enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            DFOperation *connectedOperation = obj;
            NSDictionary *bindings = [self bindingsForOperation:connectedOperation];
            NSValue *key = [NSValue valueWithPointer:(__bridge const void *)(connectedOperation)];
            //check if object is already present
            DFOperation *newOperation = [objToPointerMapping objectForKey:key];
            if (!newOperation) {
                newOperation = [connectedOperation clone:objToPointerMapping];
                [objToPointerMapping setObject:newOperation forKey:key];
            }
            [operation addDependency:newOperation withBindings:bindings];
        }];
        [operation.propertiesSet removeAllObjects];
    };
    [self safelyExecuteBlock:block];
    return operation;
}

//Do a deep copy, while copying we don't want to create dependent operations more than once,
//to resolve this a dictionary is passed which has operation to pointer mapping.
- (instancetype)clone
{
    NSMutableDictionary *objToPointerMapping = [NSMutableDictionary dictionary];
    DFOperation *operation = [self clone:objToPointerMapping];
    return operation;
}

- (NSSet *)validBindingsForOperation:(DFOperation *)operation bindings:(NSDictionary *)bindings
{
    NSSet *filteredKeys = [bindings keysOfEntriesPassingTest:^BOOL(id key, id obj, BOOL *stop) {
        NSString *toPropertyName = key;
        NSString *fromPropertyName = obj;
        BOOL isValid = YES;
        if ([fromPropertyName isKindOfClass:[NSString class]] && [toPropertyName isKindOfClass:[NSString class]]) {
            //check if operation has properties
            @try {
                //we are not interested in value
                [operation valueForKey:fromPropertyName];
                [self valueForKey:toPropertyName];
            }
            @catch (NSException *ex) {
                isValid = NO;
            }
            return isValid;
        }
        return NO;
    }];
    return filteredKeys;
}

- (NSUInteger)indexOfOperation:(DFOperation *)operation array:(NSArray *)array
{
    return [array indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        return [[obj operation] isEqual:operation];
    }];
}

- (NSDictionary *)addDependency:(DFOperation *)operation withBindings:(NSDictionary *)bindings
{
    [self addDependency:operation];
    __block NSDictionary *validBindings = nil;
    dispatch_block_t block = ^(void) {
        NSSet *filteredKeys = [self validBindingsForOperation:operation bindings:bindings];
        if ([filteredKeys count] > 0) {
            NSDictionary *validBindings = [bindings dictionaryWithValuesForKeys:[filteredKeys allObjects]];
            //associate bindings and operation
            NSUInteger index = [self indexOfOperation:operation array:self.operationBindings];
            if (index != NSNotFound) {
                DependentOperationInfo *info = [self.operationBindings objectAtIndex:index];
                [info.bindings addEntriesFromDictionary:bindings];
            }
            else {
                DependentOperationInfo *info = [[DependentOperationInfo alloc] init];
                info.bindings = [NSMutableDictionary dictionaryWithDictionary:validBindings];
                info.operation = operation;
                [self.operationBindings addObject:info];
            }
        }
        validBindings = [bindings dictionaryWithValuesForKeys:[filteredKeys allObjects]];
    };
    [self safelyExecuteBlock:block];
    return validBindings;
}

- (BOOL)connectPort:(NSString *)port toOutputOfOperation:(id<Operation>)operation
{
    if ([port length] > 0 && [self respondsToSelector:NSSelectorFromString(setterFromProperty(port))]) {
        NSDictionary *validBindings = [self addDependency:operation withBindings:@{port : @keypath(operation.output)}];
        return ([validBindings count] > 0);
    }
    return NO;
}

- (void)removeDependency:(NSOperation *)operation
{
    [super removeDependency:operation];
    dispatch_block_t block = ^(void) {
        if ([operation isKindOfClass:[DFOperation class]]) {
            //if operation is dependent
            NSUInteger index = [self indexOfOperation:(DFOperation *)operation array:self.operationBindings];
            if (index != NSNotFound) {
                //if there was a binding we remove it
                [self.operationBindings removeObjectAtIndex:index];
            }
        }
    };
    [self safelyExecuteBlock:block];
}

- (NSDictionary *)bindingsForOperation:(DFOperation *)operation
{
    __block NSDictionary *bindings = nil;
    dispatch_block_t block = ^(void) {
        [self.operationBindings enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            DependentOperationInfo *info = obj;
            if (info.operation == operation) {
                bindings = [info.bindings copy];
            }
        }];
    };
    [self safelyExecuteBlock:block];
    return bindings;
}

- (id)executionBlock
{
    return self.executionObj.executionBlock;
}

//start execution
- (void)startExecution
{
    dispatch_block_t block = ^() {
        if (!self.operationQueued) {
            if (self.queue) {
                [self.queue addOperation:self];
            }
            [DFOperation startObservingOperation:self];
            self.operationQueued = YES;
        }
        //enumerate through dependencies
        [[self connectedOperations] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            DFOperation *operation = obj;
            //if it's subclass of DFOperation then recurse, otherwise ignore
            if ([operation isKindOfClass:[DFOperation class]] && (operation.state == OperationStateReady)) {
                [operation startExecution];
            }
        }];
    };
    [self safelyExecuteBlock:block];
}

- (void)executeBindings
{
    //loop through dependent operation bindings
    [self.operationBindings enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        DependentOperationInfo *info = obj;
        DFOperation *operation = info.operation;
        NSDictionary *bindings = info.bindings;
        [bindings enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            //set property
            NSString *toProperty = key;
            NSString *fromProperty = obj;
            [self setValue:[operation valueForKey:fromProperty] forKey:toProperty];
        }];
    }];
}

- (DFOperation *)selfRef
{
    return self;
}

//prepare for execution
- (void)prepareForExecution
{
    [self executeBindings];
}

- (void)prepareExecutionObj:(Execution_Class *)executionObj
{
    [self.inputPorts enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSString *property = obj;
        id value = [self valueForKey:property];
        value = (value == [EXTNil null]) ? nil : value;
        [executionObj setValue:value atArgIndex:idx];
    }];
}

- (id)valueForUndefinedKey:(NSString *)key
{
    __block id value = nil;
    dispatch_block_t block = ^() {
        if (self.executionObj) {
            NSUInteger index = [self.inputPorts indexOfObject:key];
            if (index != NSNotFound) {
                value = [self.executionObj valueForArgAtIndex:index];
                return;
            }
        }
        value = [super valueForUndefinedKey:key];
    };
    [self safelyExecuteBlock:block];
    return value;
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key
{
    dispatch_block_t block = ^() {
        if (self.executionObj) {
            NSUInteger index = [self.inputPorts indexOfObject:key];
            if (index != NSNotFound) {
                [self.propertiesSet addObject:key];
                [self.executionObj setValue:value atArgIndex:index];
                return;
            }
        }
        [super setValue:value forUndefinedKey:key];
    };
    [self safelyExecuteBlock:block];
}

- (BOOL)isPropertySet:(NSString *)property
{
    __block BOOL propertySet = NO;
    dispatch_block_t block = ^() {
        propertySet = [self.propertiesSet containsObject:property];
    };
    [self safelyExecuteBlock:block];
    return propertySet;
}

- (NSArray *)connectedOperations
{
    return self.dependencies;
}

- (NSArray *)freePorts
{
    __block NSMutableArray *freePorts = nil;
    dispatch_block_t block = ^() {
        freePorts = [self.inputPorts mutableCopy];
        [self.operationBindings enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            DependentOperationInfo *info = obj;
            NSDictionary *bindings = info.bindings;
            [freePorts removeObjectsInArray:[bindings allKeys]];
        }];
        [freePorts removeObjectsInArray:[self.execludedPorts allObjects]];
    };
    [self safelyExecuteBlock:block];
    return freePorts;
}

- (void)setQueuePriorityRecursively:(NSOperationQueuePriority)priority
{
    self.queuePriority = priority;
    dispatch_block_t block = ^() {
        [[self connectedOperations] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            DFOperation *operation = obj;
            [operation setQueuePriorityRecursively:priority];
        }];
    };
    [self safelyExecuteBlock:block];
}

- (void)suspend
{
    dispatch_block_t block = ^() {
        if (self.isSuspended || self.state == OperationStateDone) {
            return;
        }
        self.isSuspended = YES;
    };
    [self safelyExecuteBlock:block];
    [[self connectedOperations] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        DFOperation *operation = obj;
        [operation suspend];
    }];
}

- (void)resume
{
    dispatch_block_t block = ^() {
        if (!self.isSuspended || self.state == OperationStateDone) {
            return;
        }
        self.isSuspended = NO;
    };
    [self safelyExecuteBlock:block];
    [[self connectedOperations] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        DFOperation *operation = obj;
        [operation resume];
    }];
}

- (void)safelyRemoveObserverWithBlockToken:(AMBlockToken *)token
{
    if (token) {
        OSSpinLockLock(&_stateLock);
        [self removeObserverWithBlockToken:token];
        OSSpinLockUnlock(&_stateLock);
    }
}

- (void)safelyExecuteBlock:(dispatch_block_t)block
{
    [self.operationLock lock];
    block();
    [self.operationLock unlock];
}

//this supports '.' syntax
- (void)forwardInvocation:(NSInvocation *)anInvocation
{
    NSString *selector = NSStringFromSelector([anInvocation selector]);
    __block BOOL resolved = NO;
    if (selector) {
        [self.inputPorts enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSString *property = obj;
            //getter
            if ([selector isEqualToString:property]) {
                __unsafe_unretained id val = [self valueForUndefinedKey:property];
                [anInvocation setReturnValue:&val];
                resolved = YES;
                *stop = YES;
            }
            else {
                NSString *setter = setterFromProperty(property);
                if ([selector isEqualToString:setter]) {
                    __unsafe_unretained id arg = nil;
                    [anInvocation getArgument:&arg atIndex:2];
                    [self setValue:arg forUndefinedKey:property];
                    resolved = YES;
                    *stop = YES;
                }
            }
        }];
    }
    if (!resolved) {
        [super forwardInvocation:anInvocation];
    }
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    __block NSMethodSignature *sig = [super methodSignatureForSelector:aSelector];
    if (sig) {
        return sig;
    }
    NSString *selector = NSStringFromSelector(aSelector);
    dispatch_block_t block = ^(void) {
        [self.inputPorts enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSString *port = obj;
            //check if selector is property getter
            if ([selector isEqualToString:port]) {
                sig = [super methodSignatureForSelector:@selector(output)];
                *stop = YES;
            }
            else {
                //check if selector is property setter
                NSString *setter = setterFromProperty(port);
                if ([selector isEqualToString:setter]) {
                    sig = [super methodSignatureForSelector:@selector(setOutput:)];
                    *stop = YES;
                }
            }
        }];
    };
    [self safelyExecuteBlock:block];
    return sig;
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
    __block BOOL result = [super respondsToSelector:aSelector];
    NSString *selectorString = NSStringFromSelector(aSelector);
    NSString *port;
    //selfRef is read only
    if ([selectorString isEqualToString:setterFromProperty(@keypath(self.selfRef))]) {
        port = nil;
    }
    else if ((selectorString.length > 4) &&
        ([selectorString rangeOfString:@"set"].location == 0) &&
        ([selectorString rangeOfString:@":"].location == (selectorString.length  - 1))) {
        //get setter
        port = [selectorString substringWithRange:NSMakeRange(3, selectorString.length - 4)];
        port = [NSString stringWithFormat:@"%@%@", [[port substringToIndex:1] lowercaseString], [port substringFromIndex:1]];
      
    }
    else if ([selectorString rangeOfString:@":"].location == NSNotFound) {
        port = selectorString;
    }
    if ([port length] > 0) {
        [self.inputPorts enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            if ([port isEqualToString:obj]) {
                result = YES;
                *stop = YES;
            }
        }];
    }
    return result;
}

- (void)excludePortFromFreePorts:(NSString *)port
{
    if ([port length] > 0) {
        dispatch_block_t block = ^(void) {
            if ([self.inputPorts containsObject:port]) {
                [self.execludedPorts addObject:port];
            }
        };
        [self safelyExecuteBlock:block];
    }
}

- (void)excludePortsFromFreePorts:(NSArray *)ports
{
    if ([ports count] > 0) {
        dispatch_block_t block = ^(void) {
           [ports enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
               NSString *port = obj;
               if ([self.inputPorts containsObject:port]) {
                   [self.execludedPorts addObject:port];
               }
           }];
        };
        [self safelyExecuteBlock:block];
    }
}

- (void)connectOutputToProperty:(NSString *)property ofObject:(NSObject *)object onQueue:(dispatch_queue_t)queue
{
    if (!object || [property length] == 0) {
        return;
    }
    dispatch_block_t block = ^(void){
        NSArray *array = @[property, object, ((queue == nil) ? [NSNull null] : queue)];
        [self.outputConnections addObject:array];
    };
    [self safelyExecuteBlock:block];
}

- (void)removeOutputConnectionsForObject:(NSObject *)object property:(NSString *)property
{
    if (!object || [property length] == 0) {
        return;
    }
    dispatch_block_t block = ^(void){
        __block  NSMutableIndexSet *indexSet = nil;
        [self.outputConnections enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSArray *array = obj;
            if ([array[0] isEqualToString:property] && [array[1] isEqual:object]) {
                if (!indexSet) {
                    indexSet = [NSMutableIndexSet new];
                }
                [indexSet addIndex:idx];
            }
        }];
        if (indexSet) {
            [self.outputConnections removeObjectsAtIndexes:indexSet];
        }
    };
    [self safelyExecuteBlock:block];
}

- (void)removeAllOutputConnectionsForObject:(NSObject *)object
{
    if (!object) {
        return;
    }
    dispatch_block_t block = ^(void){
        __block  NSMutableIndexSet *indexSet = nil;
        [self.outputConnections enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSArray *array = obj;
            if ([array[1] isEqual:object]) {
                if (!indexSet) {
                    indexSet = [NSMutableIndexSet new];
                }
                [indexSet addIndex:idx];
            }
        }];
        [self.outputConnections removeObjectsAtIndexes:indexSet];
    };
    [self safelyExecuteBlock:block];
}

+ (NSOperationQueue *)operationQueue
{
    return nil;
}

+ (void)startQueue
{
    [[[self class] operationQueue] setSuspended:NO];
}

+ (void)stopQueue
{
    [[[self class] operationQueue] cancelAllOperations];
    [[[self class] operationQueue] waitUntilAllOperationsAreFinished];
    [[[self class] operationQueue] setSuspended:YES];
}

#pragma mark - NSOperation methods

- (BOOL)isReady
{
    return [super isReady] && (self.state == OperationStateReady) && !self.isSuspended;
}

- (BOOL)isConcurrent
{
    return YES;
}

- (BOOL)isExecuting
{
    return (self.state == OperationStateExecuting);
}

- (BOOL)isFinished
{
    return (self.state == OperationStateDone);
}

- (void)execute
{
    __block id output = nil;
    NSError *error = nil;
    if (!self.error) {
        __block Execution_Class *executionObj = nil;
        dispatch_block_t block = ^(void) {
            executionObj = self.executionObj;
            [self prepareExecutionObj:executionObj];
        };
        [self safelyExecuteBlock:block];
        @try {
            //don't acquire lock when executing
            output = [executionObj execute];
        }
        @catch (NSException *exception) {
            error = NSErrorFromException(exception);
        }
        @finally {
            [self breakRefCycleForExecutionObj:self.executionObj];
        }
    }
    dispatch_block_t block = ^(void) {
        if (self.state == OperationStateExecuting) {
            if (!self.error && error) {
                self.error = error;
            }
            if (self.isCancelled || self.error) {
                output = [DFVoidObject new];
            }
            self.output = output;
            [self done];
        }
    };
    [self safelyExecuteBlock:block];
}

- (void)main
{
    [self execute];
}

- (void)start
{
    dispatch_block_t block = ^(void) {
        if ([super isReady] && (self.state == OperationStateReady)) {
            [self prepareForExecution];
            if (self.isCancelled) {
                [self done];
            }
            else {
                self.state = OperationStateExecuting;
            }
        }
    };
    [self safelyExecuteBlock:block];
    if (self.state == OperationStateExecuting) {
        [self main];
    }
}

- (void)breakRefCycleForExecutionObj:(Execution_Class *)executionObj
{
    NSUInteger index = [self.inputPorts indexOfObject:@keypath(self.selfRef)];
    if (index != NSNotFound) {
        [executionObj setValue:nil atArgIndex:index];
    }
}

- (void)done
{
    self.state = OperationStateDone;
    [self breakRefCycleForExecutionObj:self.executionObj];
}

@end

