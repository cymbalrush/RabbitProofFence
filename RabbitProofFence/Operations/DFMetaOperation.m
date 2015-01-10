//
//  DFMetaOperation.m
//  vf-hollywood
//
//  Created by Sinha, Gyanendra on 6/23/14.
//  Copyright (c) 2014 Conde Nast. All rights reserved.
//

#import "DFMetaOperation.h"
#import "DFBackgroundOperation.h"
#import "DFOperation_SubclassingHooks.h"
#import "OperationInfo.h"

@interface DFMetaOperation ()

@property (strong, nonatomic) DFOperation *DF_operation;

@property (strong, nonatomic) OperationInfo *DF_runningOperationInfo;

@property (readonly, nonatomic) BOOL DF_isExecutingOperation;

@end

@implementation DFMetaOperation

+ (instancetype)operationFromOperation:(DFOperation *)operation
{
    return [[[self class] alloc] initWithOperation:operation];
}

+ (instancetype)operationFromBlock:(id)block ports:(NSArray *)ports
{
    DFOperation *operation = [DFOperation operationFromBlock:block ports:ports];
    return [[[self class] alloc] initWithOperation:operation];
}

//collect all free ports
+ (void)DF_freePorts:(NSMutableArray *)freePorts
           operation:(DFOperation *)operation
             mapping:(NSMutableDictionary *)objToPointerMapping
{
    NSValue *key = [NSValue valueWithPointer:(__bridge const void *)(operation)];
    //check if object is already present
    if (objToPointerMapping[key]) {
        return;
    }
    objToPointerMapping[key] = operation;
    NSArray *operationFreePorts = [operation freePorts];
    if ([operationFreePorts count] > 0) {
        [freePorts addObject:@[operation, operationFreePorts]];
    }
    //dependent operation
    [[operation connectedOperations] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        DFOperation *connectedOperation = obj;
        [self DF_freePorts:freePorts operation:connectedOperation mapping:objToPointerMapping];
    }];
}

+ (NSDictionary *)DF_freePortsToOperationMapping:(DFOperation *)operation
{
    NSMutableArray *freePorts = [NSMutableArray array];
    NSMutableDictionary *objToPointerMapping = [NSMutableDictionary dictionary];
    [self DF_freePorts:freePorts operation:operation mapping:objToPointerMapping];
    NSMutableDictionary *mapping = [NSMutableDictionary dictionaryWithCapacity:[freePorts count]];
    [freePorts enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSArray *ports = obj[1];
        DFOperation *operation = obj[0];
        [ports enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSString *inputPort = obj;
            NSMutableSet *operations = mapping[inputPort];
            if (!operations) {
                operations = [NSMutableSet set];
                mapping[inputPort] = operations;
            }
            [operations addObject:operation];
        }];
    }];
    return mapping;
}

+ (NSDictionary *)freePortTypesFromMapping:(NSDictionary *)portToOperationMapping
{
    if (portToOperationMapping.count == 0) {
        return nil;
    }
    NSMutableDictionary *portTypes = [[NSMutableDictionary alloc] initWithCapacity:portToOperationMapping.count];
    [portToOperationMapping enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        NSString *port = key;
        Class portType = [EXTNil null];
        NSSet *operations = obj;
        if (operations.count > 0) {
            portType = [[operations anyObject] portType:port];
        }
        [operations enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
            DFOperation *operation = obj;
            Class operationPortType = [operation portType:port];
            if (portType != operationPortType) {
                NSString *reason = [NSString stringWithFormat:@"Port Type Not Equal %@", port];
                @throw [NSException exceptionWithName:DFOperationExceptionInEqualPorts reason:reason userInfo:nil];
            }
        }];
        portTypes[port] = portType;
    }];
    return portTypes;
}

//pass head of the operation
- (instancetype)initWithOperation:(DFOperation *)operation
{
    self = [self init];
    if (self) {
        if (operation) {
            self.DF_operation = operation;
            NSDictionary *portToOperationMapping = [[self class] DF_freePortsToOperationMapping:operation];
            self.DF_inputPorts = [[[self class] DF_freePortsToOperationMapping:operation] allKeys];
            self.DF_executionObj = [Execution_Class instanceForNumberOfArguments:[self.DF_inputPorts count]];
            [self DF_addPortTypes:[[self class] freePortTypesFromMapping:portToOperationMapping]];
            [self DF_setType:[operation portType:@keypath(self.DF_output)] forPort:@keypath(self.DF_output)];
        }
    }
    return self;
}

- (instancetype)DF_clone:(NSMutableDictionary *)objToPointerMapping
{
    __block DFMetaOperation *newMetaOperation = nil;
    dispatch_block_t block = ^() {
        newMetaOperation = [super DF_clone:objToPointerMapping];
        newMetaOperation.DF_operation = [self.DF_operation DF_clone:objToPointerMapping];
    };
    [self DF_safelyExecuteBlock:block];
    return newMetaOperation;
}

- (instancetype)copyWithZone:(NSZone *)zone
{
    __block DFMetaOperation *newMetaOperation = nil;
    dispatch_block_t block = ^() {
        newMetaOperation = [super copyWithZone:zone];
        newMetaOperation.DF_operation = [self.DF_operation copyWithZone:zone];
    };
    [self DF_safelyExecuteBlock:block];
    return newMetaOperation;
}

- (BOOL)DF_isExecutingOperation
{
    return (self.DF_runningOperationInfo != nil);
}

- (void)DF_operation:(DFOperation *)operation stateChanged:(id)changedValue
{
    dispatch_block_t block = ^() {
        OperationState state = [changedValue integerValue];
        if ((self.DF_state == OperationStateDone) || (state != OperationStateDone)) {
            return;
        }
        if (operation.DF_error) {
            self.DF_error = operation.DF_error;
        }
        self.DF_output = operation.DF_output;
        self.DF_runningOperationInfo = nil;
        [self DF_done];
    };
    [self DF_safelyExecuteBlock:block];
}

- (AMBlockToken *)DF_startObservingOperation:(DFOperation *)operation
{
    @weakify(self);
    @weakify(operation);
    dispatch_queue_t observationQueue = [[self class] DF_observationQueue];
    AMBlockToken *token = [operation addObserverForKeyPath:@keypath(operation.DF_state) task:^(id obj, NSDictionary *change) {
        //this causes to release all locks
        dispatch_async(observationQueue, ^{
            @strongify(self);
            @strongify(operation);
            [self DF_operation:operation stateChanged:change[NSKeyValueChangeNewKey]];
        });
    }];
    return token;
}

- (void)DF_prepareOperation:(DFOperation *)operation
{
    operation.monitoringOperation = self;
    [self.DF_inputPorts enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSString *port = obj;
        [operation setValue:[self DF_portValue:port] forKey:port];
    }];
}

- (void)DF_startOperation:(DFOperation *)operation
{
    dispatch_block_t block = ^() {
        if (!operation) {
            self.DF_state = OperationStateDone;
            return;
        }
        //prepare operation
        [self DF_prepareOperation:operation];
        [operation setQueuePriorityRecursively:self.queuePriority];
        //start observing
        OperationInfo *info = [OperationInfo new];
        info.operation = operation;
        info.stateObservationToken = [self DF_startObservingOperation:operation];
        self.DF_runningOperationInfo = info;
        if (self.DF_isSuspended) {
            [operation suspend];
        }
        //start operation
        [operation startExecution];
    };
    [self DF_safelyExecuteBlock:block];
}

- (void)suspend
{
    [super suspend];
    dispatch_block_t block = ^() {
        [self.DF_runningOperationInfo.operation suspend];
    };
    [self DF_safelyExecuteBlock:block];
}

- (void)resume
{
    [super resume];
    dispatch_block_t block = ^() {
        [self.DF_runningOperationInfo.operation resume];
    };
    [self DF_safelyExecuteBlock:block];
}

- (void)cancel
{
    __block DFOperation *executingOperation = nil;
    dispatch_block_t block = ^() {
        executingOperation = self.DF_runningOperationInfo.operation;
        self.DF_runningOperationInfo = nil;
        if (self.DF_state == OperationStateExecuting) {
            [self DF_done];
        }
    };
    [self DF_safelyExecuteBlock:block];
    //inside operation must be cancelled recursively
    if (executingOperation) {
        [executingOperation cancelRecursively];
    }
    [super cancel];
}

- (void)main
{
    dispatch_block_t block = ^(void) {
        if (self.DF_state != OperationStateExecuting) {
            return;
        }
        NSError *error = [self DF_incomingPortErrors];
        if (error) {
            self.DF_error = error;
            self.DF_output = errorObject(error);
        }
        else {
            if (self.DF_operation) {
                [self DF_startOperation:self.DF_operation];
                return;
            }
        }
        [self DF_done];
    };
    [self DF_safelyExecuteBlock:block];
}

- (void)DF_done
{
    [super DF_done];
    self.DF_runningOperationInfo = nil;
}

@end
