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

@interface DFMetaOperation ()

@property (strong, nonatomic) AMBlockToken *operationObservationToken;

@property (strong, nonatomic) DFOperation *operation;

@property (strong, nonatomic) DFOperation *executingOperation;

@property (readonly, nonatomic) BOOL isExecutingOperation;

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
+ (void)freePorts:(NSMutableArray *)freePorts operation:(DFOperation *)operation mapping:(NSMutableDictionary *)objToPointerMapping
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
        [self freePorts:freePorts operation:connectedOperation mapping:objToPointerMapping];
    }];
}

+ (NSDictionary *)freePortsToOperationMapping:(DFOperation *)operation
{
    NSMutableArray *freePorts = [NSMutableArray array];
    NSMutableDictionary *objToPointerMapping = [NSMutableDictionary dictionary];
    [self freePorts:freePorts operation:operation mapping:objToPointerMapping];
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

//pass head of the operation
- (instancetype)initWithOperation:(DFOperation *)operation
{
    self = [self init];
    if (self) {
        if (operation) {
            self.operation = operation;
            self.inputPorts = [[[self class] freePortsToOperationMapping:operation] allKeys];
            self.executionObj = [Execution_Class instanceForNumberOfArguments:[self.inputPorts count]];
        }
    }
    return self;
}

- (void)dealloc
{
    [self.executingOperation safelyRemoveObserverWithBlockToken:self.operationObservationToken];
}

- (instancetype)clone:(NSMutableDictionary *)objToPointerMapping
{
    __block DFMetaOperation *newMetaOperation = nil;
    dispatch_block_t block = ^() {
        newMetaOperation = [super clone:objToPointerMapping];
        newMetaOperation.operation = [self.operation clone:objToPointerMapping];
    };
    [self safelyExecuteBlock:block];
    return newMetaOperation;
}

- (instancetype)copyWithZone:(NSZone *)zone
{
    __block DFMetaOperation *newMetaOperation = nil;
    dispatch_block_t block = ^() {
        newMetaOperation = [super copyWithZone:zone];
        newMetaOperation.operation = [self.operation copyWithZone:zone];
    };
    [self safelyExecuteBlock:block];
    return newMetaOperation;
}

- (BOOL)isExecutingOperation
{
    return (self.executingOperation != nil);
}

- (void)operation:(DFOperation *)operation stateChanged:(id)changedValue
{
    dispatch_block_t block = ^() {
        if ((self.state == OperationStateDone) || (operation.state != OperationStateDone)) {
            return;
        }
        [operation safelyRemoveObserverWithBlockToken:self.operationObservationToken];
        self.operationObservationToken = nil;
        self.output = [self processOutput:operation.output];
        self.error = operation.error;
        self.executingOperation = nil;
        [self done];
    };
    [self safelyExecuteBlock:block];
}

- (AMBlockToken *)startObservingOperation:(DFOperation *)operation
{
    @weakify(self);
    @weakify(operation);
    dispatch_queue_t observationQueue = [[self class] operationObservationHandlingQueue];
    AMBlockToken *observationToken = [operation addObserverForKeyPath:@keypath(operation.isFinished) task:^(id obj, NSDictionary *change) {
        //this causes to release all locks
        dispatch_async(observationQueue, ^{
            @strongify(self);
            @strongify(operation);
            [self operation:operation stateChanged:change[NSKeyValueChangeNewKey]];
        });
    }];
    return observationToken;
}

- (void)prepareOperation:(DFOperation *)operation
{
    [self.inputPorts enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSString *property = obj;
        id value = [self valueForKey:property];
        value = (value == [EXTNil null]) ? nil : value;
        [operation setValue:value forKey:property];
    }];
}

- (void)startOperation:(DFOperation *)operation
{
    dispatch_block_t block = ^() {
        if (!operation) {
            self.state = OperationStateDone;
            return;
        }
        //prepare operation
        [self prepareOperation:operation];
        [operation setQueuePriorityRecursively:self.queuePriority];
        //start observing
        self.operationObservationToken = [self startObservingOperation:operation];
        self.executingOperation = operation;
        if (self.isSuspended) {
            [operation suspend];
        }
        //start operation
        [operation startExecution];
    };
    [self safelyExecuteBlock:block];
}

- (void)suspend
{
    [super suspend];
    dispatch_block_t block = ^() {
        [self.executingOperation suspend];
    };
    [self safelyExecuteBlock:block];
}

- (void)resume
{
    [super resume];
    dispatch_block_t block = ^() {
        [self.executingOperation resume];
    };
    [self safelyExecuteBlock:block];
}

- (void)cancel
{
    __block DFOperation *executingOperation = nil;
    dispatch_block_t block = ^() {
        executingOperation = self.executingOperation;
        if (self.operationObservationToken) {
            [self.executingOperation removeObserverWithBlockToken:self.operationObservationToken];
            self.operationObservationToken = nil;
        }
        if (self.state == OperationStateExecuting) {
            [self done];
        }
    };
    [self safelyExecuteBlock:block];
    //inside operation must be cancelled recursively
    if (executingOperation) {
        [executingOperation cancelRecursively];
    }
    [super cancel];
}

- (void)main
{
    dispatch_block_t block = ^(void) {
        if (self.state != OperationStateExecuting) {
            return;
        }
        if (!self.error) {
            if (self.operation) {
                [self startOperation:self.operation];
                return;
            }
        }
        self.output = [self processOutput:nil];
        [self done];
    };
    [self safelyExecuteBlock:block];
}

- (void)done
{
    [super done];
    self.executingOperation = nil;
}

@end
