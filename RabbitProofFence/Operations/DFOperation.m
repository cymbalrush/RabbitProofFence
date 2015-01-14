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
#import "Connection.h"
#import "NSObject+BlockObservation.h"
#import "EXTScope.h"
#import "EXTKeyPathCoding.h"
#import <libkern/OSAtomic.h>
#import "DFVoidObject.h"
#import "EXTNil.h"
#import "DFErrorObject.h"

NSString * const DFOperationExceptionInvalidBlockSignature = @"DFOperationExceptionInvalidBlockSignature";
NSString * const DFOperationExceptionDuplicatePropertyNames = @"DFOperationExceptionDuplicatePropertyNames";
NSString * const DFOperationExceptionHandlerDomain = @"DFOperationExceptionHandlerDomain";
NSString * const DFOperationExceptionReason = @"DFOperationExceptionReason";
NSString * const DFOperationExceptionUserInfo = @"DFOperationExceptionUserInfo";
NSString * const DFOperationExceptionName = @"DFOperationException";
NSString * const DFOperationExceptionInEqualPorts = @"DFOperationOperationExceptionInEqualInputPorts";
NSString * const DFOperationExceptionInvalidInitialization = @"DFOperationExceptionInvalidInitialization";
NSString * const DFOperationExceptionMethodNotSupported = @"DFOperationExceptionMethodNotSupported";
NSString * const DFOperationExceptionIncorrectParameter = @"DFOperationExceptionIncorrectParameter";
NSString * const DFErrorKeyName = @"DFErrorKey";
const int DFOperationExceptionEncounteredErrorCode = 1000;
const int DFOperationInComingPortErrorCode = 1001;

static char const * const OPERATION_SYNC_QUEUE = "com.operations.syncQueue";
static char const * const OPERATION_START_QUEUE = "com.operations.startQueue";
static char const * const OPERATION_OBSERVATION_HANDLING_QUEUE = "com.operations.observationHandlingQueue";

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

NS_INLINE Class classFromType(const char *type)
{
    const char idType = @encode(id)[0];
    if (type[0] == idType) {
        NSString *typeStr = [NSString stringWithCString:type encoding:NSUTF8StringEncoding];
        typeStr = [typeStr stringByReplacingCharactersInRange:NSMakeRange(0, 1)
                                                   withString:@""];
        typeStr = [typeStr stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\""]];
        Class class = NSClassFromString(typeStr);
        if (class) {
            return class;
        }
    }
    return [EXTNil null];
}

NSArray *argTypesFromBlockDesc(BlockDescription *blockDesc)
{
    if (!blockDesc) {
        return nil;
    }
    NSMethodSignature  *sig = blockDesc.blockSignature;
    NSUInteger n = [sig numberOfArguments];
    if (n < 2) {
        return nil;
    }
    NSMutableArray *types = [NSMutableArray arrayWithCapacity:(n - 1)];
    for (int i = 1; i < n; i++) {
        Class argClass = classFromType([sig getArgumentTypeAtIndex:i]);
        types[(i - 1)] = argClass;
    }
    return types;
}

Class returnTypeFromBlockDesc(BlockDescription *blockDesc)
{
    if (!blockDesc) {
        return nil;
    }
    NSMethodSignature *sig = blockDesc.blockSignature;
    return classFromType([sig methodReturnType]);
}

BlockDescription *blockDesc(id block)
{
    if (!block) {
        return nil;
    }
    return [[BlockDescription alloc] initWithBlock:block];
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

void methodNotSupported()
{
    NSString *reason = [NSString stringWithFormat:@"Method not supported"];
    @throw [NSException exceptionWithName:DFOperationExceptionMethodNotSupported reason:reason userInfo:nil];
}

NSString *setterFromProperty(NSString *property)
{
    if ([property length] == 0) {
        return @"";
    }
    return [NSString stringWithFormat:@"set%@%@:",
            [[property substringToIndex:1] uppercaseString],
            [property substringFromIndex:1]];
}

NSDictionary *portErrors(NSError *error)
{
    if ([error.domain isEqualToString:DFOperationExceptionName] && error.code == DFOperationInComingPortErrorCode) {
        return error.userInfo[DFErrorKeyName];
    }
    return nil;
}

NSError *createErrorFromPortErrors(NSDictionary *portErrors)
{
    NSError *error = [NSError errorWithDomain:DFOperationExceptionName
                                         code:DFOperationInComingPortErrorCode
                                     userInfo:portErrors];
    return error;
}

@interface DFOperation ()

@property (assign, nonatomic) OperationState DF_state;

@property (strong, nonatomic) NSError *DF_error;

@property (strong, nonatomic) id DF_output;

@property (strong, nonatomic) NSMutableDictionary *DF_connections;

@property (strong, nonatomic) AMBlockToken *DF_isFinishedObservationToken;

@property (strong, nonatomic) AMBlockToken *DF_isReadyObservationToken;

@property (assign, nonatomic) volatile OSSpinLock DF_stateLock;

@property (strong, nonatomic) NSRecursiveLock *DF_operationLock;

@property (strong, nonatomic) Execution_Class *DF_executionObj;

@property (assign, nonatomic) BOOL DF_isSuspended;

@property (strong, nonatomic) NSMutableSet *DF_propertiesSet;

@property (strong, nonatomic) NSArray *DF_inputPorts;

@property (assign, nonatomic) BOOL DF_operationQueued;

@property (strong, nonatomic) NSMutableSet *DF_excludedPorts;

@property (strong, nonatomic) NSMutableArray *DF_outputConnections;

@property (strong, nonatomic) NSMutableDictionary *DF_portTypes;

@property (weak, nonatomic) DFOperation *monitoringOperation;

- (void)DF_safelyRemoveObserver:(AMBlockToken *)token;

@end

@implementation DFOperation

+ (Execution_Class *)DF_executionObjFromBlock:(id)block
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
+ (NSString *)DF_propertyKeyFromState:(OperationState)state
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
    return [key isEqualToString:@keypath(operation.DF_state)] ? NO : [super automaticallyNotifiesObserversForKey:key];
}

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key
{
    DFOperation *operation = nil;
    NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
    NSSet *properties = nil;
    if ([key isEqualToString:@keypath(operation.isReady)]) {
        properties = [NSSet setWithObject:@keypath(operation.DF_isSuspended)];
    }
    else if ([key isEqualToString:@keypath(operation.state)]) {
        properties = [NSSet setWithObject:@keypath(operation.DF_state)];
    }
    else if ([key isEqualToString:@keypath(operation.output)]) {
        properties = [NSSet setWithObject:@keypath(operation.DF_output)];
    }
    else if ([key isEqualToString:@keypath(operation.isSuspended)]) {
        properties = [NSSet setWithObject:@keypath(operation.DF_isSuspended)];
    }
    if (properties) {
        keyPaths = [keyPaths setByAddingObjectsFromSet:properties];
    }
    return keyPaths;
}

NS_INLINE BOOL StateTransitionIsValid(OperationState fromState, OperationState toState, BOOL isCancelled) {
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

+ (dispatch_queue_t)DF_syncQueue
{
    static dispatch_queue_t queue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create(OPERATION_SYNC_QUEUE, DISPATCH_QUEUE_SERIAL);
    });
    return queue;
}

+ (dispatch_queue_t)DF_startQueue
{
    static dispatch_queue_t queue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create(OPERATION_START_QUEUE, DISPATCH_QUEUE_CONCURRENT);
    });
    return queue;
}

+ (dispatch_queue_t)DF_observationQueue
{
    static dispatch_queue_t queue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create(OPERATION_OBSERVATION_HANDLING_QUEUE, DISPATCH_QUEUE_SERIAL);
    });
    return queue;
}

+ (NSMutableDictionary *)DF_dependentOperations
{
    static NSMutableDictionary *operations = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        operations = [NSMutableDictionary dictionary];
    });
    return operations;
}

+ (NSMutableSet *)DF_runningOperations
{
    static NSMutableSet *operations = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        operations = [NSMutableSet set];
    });
    return operations;
}

+ (void)DF_startOperation:(DFOperation *)operation
{
    // prepare and start it
    dispatch_async([DFOperation DF_startQueue], ^{
        if (operation.DF_state == OperationStateReady) {
            [operation start];
        }
    });
}

+ (void)DF_removeObservations:(DFOperation *)operation
{
    //remove state observation
    AMBlockToken *observationToken = operation.DF_isFinishedObservationToken;
    [operation DF_safelyRemoveObserver:observationToken];
    operation.DF_isFinishedObservationToken = nil;
    
    observationToken = operation.DF_isReadyObservationToken;
    [operation DF_safelyRemoveObserver:observationToken];
    operation.DF_isReadyObservationToken = nil;
}

+ (void)DF_cleanup:(DFOperation *)finishedOperation
{
    NSValue *key = [NSValue valueWithPointer:(__bridge const void *)(finishedOperation)];
    NSMutableDictionary *mapping = [DFOperation DF_dependentOperations];
    [[finishedOperation class] DF_removeObservations:finishedOperation];
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

+ (void)DF_startDependentOperations:(DFOperation *)finishedOperation
{
    NSValue *key = [NSValue valueWithPointer:(__bridge const void *)(finishedOperation)];
    NSMutableDictionary *mapping = [DFOperation DF_dependentOperations];
    __block NSMutableSet *operationsToStart = nil;
    NSMutableSet *dependentOperations = mapping[key];
    [dependentOperations enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        //find out dependent operation
        DFOperation *dependentOperation = obj;
        if (dependentOperation == finishedOperation) {
            return;
        }
        if (!dependentOperation.queue && (dependentOperation.DF_state == OperationStateReady)) {
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
    [self DF_cleanup:finishedOperation];
    if (operationsToStart.count > 0) {
        [operationsToStart enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
            DFOperation *operation = obj;
            [[operation class] DF_startOperation:operation];
        }];
    }
}

+ (void)DF_observeOperation:(DFOperation *)operation
{
    if (!operation) {
        return;
    }
    dispatch_sync([DFOperation DF_syncQueue], ^{
        [[DFOperation DF_runningOperations] addObject:operation];
        @weakify(operation);
        //add internal observer for isFinished
        AMBlockToken *token = [operation addObserverForKeyPath:@keypath(operation.isFinished) task:^(id obj, NSDictionary *change) {
                dispatch_async([DFOperation DF_syncQueue], ^{
                    @strongify(operation);
                    if (!operation) {
                        return;
                    }
                    [[operation class] DF_startDependentOperations:operation];
                    [[DFOperation DF_runningOperations] removeObject:operation];
                });
        }];
        operation.DF_isFinishedObservationToken = token;
        //if there is no queue, add internal observer for isReady
        if (!operation.queue) {
            if (operation.isReady) {
                [[operation class] DF_startOperation:operation];
            }
            else {
                token = [operation addObserverForKeyPath:@keypath(operation.isReady) task:^(id obj, NSDictionary *change) {
                    //check operation state
                    if ([[change valueForKey:NSKeyValueChangeNewKey] boolValue]) {
                        //move it to the same queue
                        dispatch_async([DFOperation DF_syncQueue], ^{
                            @strongify(operation);
                            if (!operation) {
                                return;
                            }
                            AMBlockToken *observationToken = operation.DF_isReadyObservationToken;
                            [operation DF_safelyRemoveObserver:observationToken];
                            operation.DF_isReadyObservationToken = nil;
                            //make sure that operation can be executed
                            [[operation class] DF_startOperation:operation];
                        });
                    }
                }];
                operation.DF_isReadyObservationToken = token;
            }
        }
        NSArray *dependencies = operation.dependencies;
        if ([dependencies count] > 0) {
            NSMutableDictionary *mapping = [DFOperation DF_dependentOperations];
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

+ (instancetype)operationFromBlock:(id)block ports:(NSArray *)ports
{
    DFOperation *operation = [self new];
    operation.DF_inputPorts = [ports copy];
    operation.executionBlock = block;
    [operation DF_populateTypesFromBlock:block ports:ports];
    return operation;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _DF_stateLock = OS_SPINLOCK_INIT;
        _DF_operationLock = [NSRecursiveLock new];
        _DF_connections = [NSMutableDictionary new];
        _DF_propertiesSet = [NSMutableSet new];
        _DF_outputConnections = [NSMutableArray array];
        _DF_excludedPorts = [NSMutableSet setWithObject:@keypath(self.selfRef)];
        _DF_output = [DFVoidObject new];
        _DF_portTypes = [NSMutableDictionary new];
        _queue = [[self class] operationQueue];
    }
    return self;
}

- (id)output
{
    return self.DF_output;
}

- (NSError *)error
{
    return self.DF_error;
}

- (OperationState)state
{
    return self.DF_state;
}

- (BOOL)isSuspended
{
    return self.DF_isSuspended;
}

- (void)setExecutionBlock:(id)executionBlock
{
    if (self.DF_executionObj.executionBlock != executionBlock) {
        Execution_Class *executionObj = [DFOperation DF_executionObjFromBlock:executionBlock];
        NSArray *ports = self.DF_inputPorts;
        NSUInteger n = [executionObj numberOfPorts];
        if ((n > 0) && !([ports count] == n && [[NSSet setWithArray:ports] count] == [ports count])) {
            //throw an exception
            NSString *reason = [NSString stringWithFormat:@"Duplicate property names, make sure that property names are unique"];
            @throw [NSException exceptionWithName:DFOperationExceptionDuplicatePropertyNames reason:reason userInfo:nil];
        }
        self.DF_executionObj = executionObj;
        self.DF_executionObj.executionBlock = executionBlock;
    }
}

- (void)setDF_state:(OperationState)state
{
    OSSpinLockLock(&_DF_stateLock);
    if (_DF_state == state) {
        OSSpinLockUnlock(&_DF_stateLock);
        return;
    }
    if (StateTransitionIsValid(_DF_state, state, self.isCancelled)) {
        NSString *oldStateKey = [DFOperation DF_propertyKeyFromState:_DF_state];
        NSString *newStateKey = [DFOperation DF_propertyKeyFromState:state];
        [self willChangeValueForKey:oldStateKey];
        [self willChangeValueForKey:newStateKey];
        [self willChangeValueForKey:@keypath(self.DF_state)];
        _DF_state = state;
        [self didChangeValueForKey:@keypath(self.DF_state)];
        [self didChangeValueForKey:newStateKey];
        [self didChangeValueForKey:oldStateKey];
    }
    OSSpinLockUnlock(&_DF_stateLock);
}

- (void)setDF_output:(id)output
{
    _DF_output = output;
    [self.DF_outputConnections enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSArray *array = obj;
        NSString *property = array[0];
        NSObject *object = array[1];
        dispatch_queue_t queue = array[2];
        if (queue == [EXTNil null]) {
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

+ (void)DF_copyExcludedPortValuesFromOperation:(DFOperation *)fromOperation
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

NS_INLINE DFOperation *copyOperation(DFOperation *operation)
{
    DFOperation *newOperation = [[operation class] new];
    newOperation.DF_executionObj = [operation.DF_executionObj copy];
    newOperation.DF_inputPorts = [operation.DF_inputPorts copy];
    newOperation.name = [operation.name copy];
    newOperation.queue = operation.queue;
    newOperation.queuePriority = operation.queuePriority;
    NSMutableSet *excludedPorts = [operation.DF_excludedPorts copy];
    newOperation.DF_excludedPorts = excludedPorts;
    newOperation.DF_portTypes = [operation.DF_portTypes copy];
    //copy excluded port values
    [[operation class] DF_copyExcludedPortValuesFromOperation:operation
                                               toOperation:newOperation
                                             excludedPorts:excludedPorts];
    return newOperation;
}

- (instancetype)copyWithZone:(NSZone *)zone
{
    __block DFOperation *operation = nil;
    dispatch_block_t block = ^(void) {
        //brek ref cycle
        [self DF_breakRefCycleForExecutionObj:self.DF_executionObj];
        operation = copyOperation(self);
        //copy dependencies
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
        [operation.DF_propertiesSet removeAllObjects];
    };
    [self DF_safelyExecuteBlock:block];
    return operation;
}

- (instancetype)DF_clone:(NSMutableDictionary *)objToPointerMapping
{
    __block DFOperation *operation = nil;
    dispatch_block_t block = ^(void) {
        [self DF_breakRefCycleForExecutionObj:self.DF_executionObj];
        operation = copyOperation(self);
        //clone dependencies
        [self.dependencies enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            DFOperation *connectedOperation = obj;
            NSDictionary *bindings = [self bindingsForOperation:connectedOperation];
            NSValue *key = [NSValue valueWithPointer:(__bridge const void *)(connectedOperation)];
            //check if object is already present
            DFOperation *newOperation = objToPointerMapping[key];
            if (!newOperation) {
                newOperation = [connectedOperation DF_clone:objToPointerMapping];
                [objToPointerMapping setObject:newOperation forKey:key];
            }
            [operation addDependency:newOperation withBindings:bindings];
        }];
        [operation.DF_propertiesSet removeAllObjects];
    };
    [self DF_safelyExecuteBlock:block];
    return operation;
}

//Do a deep copy, while copying we don't want to create dependent operations more than once,
//to resolve this a dictionary is passed which has operation to pointer mapping.
- (instancetype)DF_clone
{
    NSMutableDictionary *objToPointerMapping = [NSMutableDictionary dictionary];
    DFOperation *operation = [self DF_clone:objToPointerMapping];
    return operation;
}

- (NSArray *)inputPorts
{
    return [self.DF_inputPorts copy];
}

- (NSSet *)DF_validBindingsForOperation:(DFOperation *)operation bindings:(NSDictionary *)bindings
{
    NSSet *filteredKeys = [bindings keysOfEntriesPassingTest:^BOOL(id key, id obj, BOOL *stop) {
        NSString *toPort = key;
        NSString *fromPort = obj;
        return [self canConnectPort:fromPort ofOperation:operation toPort:toPort];
    }];
    return filteredKeys;
}

- (NSDictionary *)addDependency:(DFOperation *)operation withBindings:(NSDictionary *)bindings
{
    if (!operation || operation == self) {
        return nil;
    }
    if (bindings.count == 0) {
        [self addDependency:operation];
        return nil;
    }
    __block NSDictionary *validBindings = nil;
    dispatch_block_t block = ^(void) {
        NSSet *filteredKeys = [self DF_validBindingsForOperation:operation bindings:bindings];
        [filteredKeys enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
            NSString *toPort = obj;
            NSString *fromPort = bindings[toPort];
            //create info for operation
            Connection *info = [Connection new];
            info.operation = operation;
            info.fromPort = fromPort;
            info.toPort = toPort;
            Class portType = self.DF_portTypes[toPort];
            if (!portType || portType == [EXTNil null]) {
                portType = [operation portType:fromPort];
            }
            info.inferredType = portType;
            self.DF_connections[toPort] = info;
        }];
        validBindings = [bindings dictionaryWithValuesForKeys:[filteredKeys allObjects]];
     };
    [self DF_safelyExecuteBlock:block];
    if ([validBindings count] > 0) {
        [self addDependency:operation];
    }
    return validBindings;
}

- (BOOL)connectPort:(NSString *)port toOutputOfOperation:(DFOperation *)operation
{
    if ([port length] > 0 && [self respondsToSelector:NSSelectorFromString(setterFromProperty(port))]) {
        NSDictionary *validBindings = [self addDependency:operation withBindings:@{port : @keypath(operation.DF_output)}];
        return ([validBindings count] > 0);
    }
    return NO;
}

- (void)removeDependency:(NSOperation *)operation
{
    [super removeDependency:operation];
    dispatch_block_t block = ^(void) {
        if ([operation isKindOfClass:[DFOperation class]]) {
            NSMutableArray *connectionsToRemove = [NSMutableArray array];
            [self.DF_connections enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                Connection *info = obj;
                if ([info.operation isEqual:operation]) {
                    [connectionsToRemove addObject:key];
                }
            }];
            [self.DF_connections removeObjectsForKeys:connectionsToRemove];
        }
    };
    [self DF_safelyExecuteBlock:block];
}

- (NSDictionary *)bindingsForOperation:(DFOperation *)operation
{
    __block NSMutableDictionary *bindings = [NSMutableDictionary dictionary];
    dispatch_block_t block = ^(void) {
        [self.DF_connections enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            Connection *info = obj;
            DFOperation *connectedOperation = info.operation;
            if (connectedOperation == operation) {
                NSString *connectedToProperty = key;
                NSString *connectedFromProperty = info.fromPort;
                bindings[connectedToProperty] = connectedFromProperty;
            }
        }];
    };
    [self DF_safelyExecuteBlock:block];
    return bindings;
}

- (id)executionBlock
{
    return self.DF_executionObj.executionBlock;
}

//start execution
- (void)startExecution
{
    dispatch_block_t block = ^() {
        if (!self.DF_operationQueued) {
            if (self.queue) {
                [self.queue addOperation:self];
            }
            [DFOperation DF_observeOperation:self];
            self.DF_operationQueued = YES;
        }
        //enumerate through dependencies
        [[self connectedOperations] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            DFOperation *operation = obj;
            //if it's subclass of DFOperation then recurse, otherwise ignore
            if ([operation isKindOfClass:[DFOperation class]] && (operation.DF_state == OperationStateReady)) {
                [operation startExecution];
            }
        }];
    };
    [self DF_safelyExecuteBlock:block];
}

- (void)DF_executeBindings
{
    //loop through dependent operation bindings
    [self.DF_connections enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        Connection *info = obj;
        DFOperation *operation = info.operation;
        [self setValue:[operation valueForKey:info.fromPort] forKey:info.toPort];
    }];
}

- (DFOperation *)selfRef
{
    return self;
}

//prepare for execution
- (void)DF_prepareForExecution
{
    [self DF_executeBindings];
}

- (id)DF_portValue:(NSString *)port
{
    id value = [self valueForKey:port];
    value = (value == [EXTNil null]) ? nil : value;
    return value;
}

- (void)DF_prepareExecutionObj:(Execution_Class *)executionObj
{
    [self.DF_inputPorts enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if (idx >= executionObj.numberOfPorts) {
            *stop = YES;
            return;
        }
        NSString *port = obj;
        [executionObj setValue:[self DF_portValue:port] atArgIndex:idx];
    }];
}

- (NSError *)DF_incomingPortErrors
{
    __block NSMutableDictionary *portErrors = nil;
    dispatch_block_t block = ^(void) {
        [self.DF_inputPorts enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSString *port = obj;
            id value = [self valueForKey:port];
            if (isDFErrorObject(value)) {
                if (!portErrors) {
                    portErrors = [NSMutableDictionary new];
                }
                DFErrorObject *errorObj = value;
                NSError *error = errorObj.error;
                if (error) {
                    portErrors[port] = error;
                }
            }
        }];
    };
    [self DF_safelyExecuteBlock:block];
    if (portErrors.count > 0) {
        return createErrorFromPortErrors(portErrors);
    }
    return nil;
}

- (id)valueForUndefinedKey:(NSString *)key
{
    __block id value = nil;
    dispatch_block_t block = ^() {
        if (self.DF_executionObj) {
            NSUInteger index = [self.DF_inputPorts indexOfObject:key];
            if (index != NSNotFound) {
                value = [self.DF_executionObj valueForArgAtIndex:index];
                return;
            }
        }
        value = [super valueForUndefinedKey:key];
    };
    [self DF_safelyExecuteBlock:block];
    return value;
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key
{
    dispatch_block_t block = ^() {
        if (self.DF_executionObj) {
            NSUInteger index = [self.DF_inputPorts indexOfObject:key];
            if (index != NSNotFound) {
                [self.DF_propertiesSet addObject:key];
                [self.DF_executionObj setValue:value atArgIndex:index];
                return;
            }
        }
        [super setValue:value forUndefinedKey:key];
    };
    [self DF_safelyExecuteBlock:block];
}

- (BOOL)DF_isPropertySet:(NSString *)property
{
    __block BOOL propertySet = NO;
    dispatch_block_t block = ^() {
        propertySet = [self.DF_propertiesSet containsObject:property];
    };
    [self DF_safelyExecuteBlock:block];
    return propertySet;
}

- (NSArray *)connectedOperations
{
    return self.dependencies;
}

- (NSDictionary *)connections
{
    return [self.DF_connections copy];
}

- (NSArray *)freePorts
{
    __block NSMutableArray *freePorts = nil;
    dispatch_block_t block = ^() {
        freePorts = [self.DF_inputPorts mutableCopy];
        [self.connections enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            Connection *info = obj;
            [freePorts removeObject:info.toPort];
        }];
        if (self.DF_excludedPorts.count > 0) {
            [freePorts removeObjectsInArray:[self.DF_excludedPorts allObjects]];
        }
    };
    [self DF_safelyExecuteBlock:block];
    return freePorts;
}

- (Class)portType:(NSString *)port
{
    __block Class type = nil;
    dispatch_block_t block = ^(void) {
        Connection *info = self.connections[port];
        if (info.inferredType) {
            type = info.inferredType;
        }
        else if ([port isEqualToString:@keypath(self.output)]) {
            type = self.DF_portTypes[@keypath(self.DF_output)];
        }
        else {
            type = self.DF_portTypes[port];
        }
    };
    [self DF_safelyExecuteBlock:block];
    return type;
}

- (BOOL)DF_setType:(Class)type forPort:(NSString *)port
{
    if (type) {
        self.DF_portTypes[port] = type;
        return YES;
    }
    return NO;
}

- (void)DF_addPortTypes:(NSDictionary *)portTypes
{
    if (portTypes) {
        [self.DF_portTypes addEntriesFromDictionary:portTypes];
    }
}

- (NSDictionary *)portTypes
{
    __block NSDictionary *result = nil;
    dispatch_block_t block = ^(void) {
        result = [self.DF_portTypes copy];
    };
    [self DF_safelyExecuteBlock:block];
    return result;
}

- (NSDictionary *)freePortTypes
{
    NSDictionary *portTypes = self.portTypes;
    NSArray *freePorts = self.freePorts;
    NSMutableDictionary *freePortTypes = [[NSMutableDictionary alloc] initWithCapacity:freePorts.count];
    [freePorts enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSString *port = obj;
        Class type = portTypes[port];
        if (type) {
            freePortTypes[port] = type;
        }
    }];
    return freePortTypes;;
}

- (BOOL)canConnectPort:(NSString *)port ofOperation:(DFOperation *)operation toPort:(NSString *)toPort
{
    Class fromPortClass = [operation portType:port];
    Class toPortClass = [self portType:toPort];
    BOOL result = NO;
    if (toPortClass == [EXTNil null] || fromPortClass == [EXTNil null]) {
        result = YES;
    }
    else {
        result = [fromPortClass isSubclassOfClass:toPortClass];
    }
    return result;
}

- (void)DF_populateTypesFromBlock:(id)block ports:(NSArray *)ports
{
    BlockDescription *desc = blockDesc(block);
    if (desc) {
        NSArray *types = argTypesFromBlockDesc(desc);
        [ports enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSString *port = obj;
            [self DF_setType:types[idx] forPort:port];
        }];
        [self DF_setType:returnTypeFromBlockDesc(desc) forPort:@keypath(self.DF_output)];
    }
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
    [self DF_safelyExecuteBlock:block];
}

- (void)suspend
{
    dispatch_block_t block = ^() {
        if (self.DF_isSuspended || self.DF_state == OperationStateDone) {
            return;
        }
        self.DF_isSuspended = YES;
    };
    [self DF_safelyExecuteBlock:block];
    [[self connectedOperations] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        DFOperation *operation = obj;
        [operation suspend];
    }];
}

- (void)resume
{
    dispatch_block_t block = ^() {
        if (!self.DF_isSuspended || self.DF_state == OperationStateDone) {
            return;
        }
        self.DF_isSuspended = NO;
    };
    [self DF_safelyExecuteBlock:block];
    [[self connectedOperations] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        DFOperation *operation = obj;
        [operation resume];
    }];
}

- (void)DF_safelyRemoveObserver:(AMBlockToken *)token
{
    if (token) {
        OSSpinLockLock(&_DF_stateLock);
        [self removeObserverWithBlockToken:token];
        OSSpinLockUnlock(&_DF_stateLock);
    }
}

- (void)DF_safelyExecuteBlock:(dispatch_block_t)block
{
    [self.DF_operationLock lock];
    block();
    [self.DF_operationLock unlock];
}

//this supports '.' syntax
- (void)forwardInvocation:(NSInvocation *)anInvocation
{
    NSString *selector = NSStringFromSelector([anInvocation selector]);
    __block BOOL resolved = NO;
    if (selector) {
        [self.DF_inputPorts enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
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
        [self.DF_inputPorts enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSString *port = obj;
            //check if selector is property getter
            if ([selector isEqualToString:port]) {
                sig = [super methodSignatureForSelector:@selector(DF_output)];
                *stop = YES;
            }
            else {
                //check if selector is property setter
                NSString *setter = setterFromProperty(port);
                if ([selector isEqualToString:setter]) {
                    sig = [super methodSignatureForSelector:@selector(setDF_output:)];
                    *stop = YES;
                }
            }
        }];
    };
    [self DF_safelyExecuteBlock:block];
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
        [self.DF_inputPorts enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
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
            if ([self.DF_inputPorts containsObject:port]) {
                [self.DF_excludedPorts addObject:port];
            }
        };
        [self DF_safelyExecuteBlock:block];
    }
}

- (void)excludePortsFromFreePorts:(NSArray *)ports
{
    if ([ports count] > 0) {
        dispatch_block_t block = ^(void) {
           [ports enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
               NSString *port = obj;
               if ([self.DF_inputPorts containsObject:port]) {
                   [self.DF_excludedPorts addObject:port];
               }
           }];
        };
        [self DF_safelyExecuteBlock:block];
    }
}

- (void)connectOutputToProperty:(NSString *)property ofObject:(NSObject *)object onQueue:(dispatch_queue_t)queue
{
    if (!object || [property length] == 0) {
        return;
    }
    dispatch_block_t block = ^(void){
        NSArray *array = @[property, object, ((queue == nil) ? [NSNull null] : queue)];
        [self.DF_outputConnections addObject:array];
    };
    [self DF_safelyExecuteBlock:block];
}

- (void)removeOutputConnectionsForObject:(NSObject *)object property:(NSString *)property
{
    if (!object || [property length] == 0) {
        return;
    }
    dispatch_block_t block = ^(void){
        __block  NSMutableIndexSet *indexSet = nil;
        [self.DF_outputConnections enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSArray *array = obj;
            if ([array[0] isEqualToString:property] && [array[1] isEqual:object]) {
                if (!indexSet) {
                    indexSet = [NSMutableIndexSet new];
                }
                [indexSet addIndex:idx];
            }
        }];
        if (indexSet) {
            [self.DF_outputConnections removeObjectsAtIndexes:indexSet];
        }
    };
    [self DF_safelyExecuteBlock:block];
}

- (void)removeAllOutputConnectionsForObject:(NSObject *)object
{
    if (!object) {
        return;
    }
    dispatch_block_t block = ^(void){
        __block  NSMutableIndexSet *indexSet = nil;
        [self.DF_outputConnections enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSArray *array = obj;
            if ([array[1] isEqual:object]) {
                if (!indexSet) {
                    indexSet = [NSMutableIndexSet new];
                }
                [indexSet addIndex:idx];
            }
        }];
        [self.DF_outputConnections removeObjectsAtIndexes:indexSet];
    };
    [self DF_safelyExecuteBlock:block];
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
    return [super isReady] && (self.DF_state == OperationStateReady) && !self.DF_isSuspended;
}

- (BOOL)isConcurrent
{
    return YES;
}

- (BOOL)isExecuting
{
    return (self.DF_state == OperationStateExecuting);
}

- (BOOL)isFinished
{
    return (self.DF_state == OperationStateDone);
}

- (BOOL)DF_execute
{
    __block id output = nil;
    __block BOOL result = NO;
    NSError *error = [self DF_incomingPortErrors];
    if (!error) {
        __block Execution_Class *executionObj = nil;
        dispatch_block_t block = ^(void) {
            executionObj = self.DF_executionObj;
            [self DF_prepareExecutionObj:executionObj];
        };
        [self DF_safelyExecuteBlock:block];
        @try {
            //don't acquire lock when executing
            output = [executionObj execute];
        }
        @catch (NSException *exception) {
            error = NSErrorFromException(exception);
        }
        @finally {
            [self DF_breakRefCycleForExecutionObj:self.DF_executionObj];
        }
    }
    dispatch_block_t block = ^(void) {
        if (self.DF_state == OperationStateExecuting) {
            if (!self.isCancelled) {
                if (error) {
                    self.DF_error = error;
                    self.DF_output = errorObject(error);
                }
                else {
                    self.DF_output = output;
                    result = YES;
                }
            }
            [self DF_done];
        }
    };
    [self DF_safelyExecuteBlock:block];
    return result;
}

- (void)main
{
    [self DF_execute];
}

- (void)start
{
    dispatch_block_t block = ^(void) {
        if ([super isReady] && (self.DF_state == OperationStateReady)) {
            [self DF_prepareForExecution];
            if (self.isCancelled) {
                [self DF_done];
            }
            else {
                self.DF_state = OperationStateExecuting;
            }
        }
    };
    [self DF_safelyExecuteBlock:block];
    if (self.DF_state == OperationStateExecuting) {
        [self main];
    }
}

- (void)DF_breakRefCycleForExecutionObj:(Execution_Class *)executionObj
{
    NSUInteger index = [self.DF_inputPorts indexOfObject:@keypath(self.selfRef)];
    if (index != NSNotFound) {
        [executionObj setValue:nil atArgIndex:index];
    }
}

- (void)DF_done
{
    self.DF_state = OperationStateDone;
    [self DF_breakRefCycleForExecutionObj:self.DF_executionObj];
}

@end

