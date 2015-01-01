//
//  DFParallelOperation.m
//  vf-hollywood
//
//  Created by Sinha, Gyanendra on 6/23/14.
//  Copyright (c) 2014 Conde Nast. All rights reserved.
//

#import "DFParallelOperation.h"
#import "DFReactiveOperation_SubclassingHooks.h"
#import "OperationInfo.h"
#import <objc/runtime.h>
#import "EXTNil.h"

static char const * const OPERATION_INDEX_KEY = "operationIndexKey";

@interface DFOperation (Parallel)

@property (assign, nonatomic) NSUInteger operationIndex;

@end

@implementation DFOperation (Parallel)

- (NSUInteger)operationIndex
{
    return [objc_getAssociatedObject(self, OPERATION_INDEX_KEY) intValue];
}

- (void)setOperationIndex:(NSUInteger)operationIndex
{
    objc_setAssociatedObject(self, OPERATION_INDEX_KEY, @(operationIndex), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

@interface DFParallelOperation ()

@property (nonatomic, strong) NSMutableDictionary *operationsInProgress;

@property (assign, nonatomic) NSUInteger currentOperationIndex;

@end

@implementation DFParallelOperation

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.operationsInProgress = [NSMutableDictionary dictionary];
        self.maxConcurrentOperations = 1;
        self.outputInOrder = YES;
        self.currentOperationIndex = 0;
    }
    return self;
}

- (NSUInteger)operationsToStart
{
   __block NSUInteger operationsToStart = 0;
    dispatch_block_t block = ^(void) {
        operationsToStart = self.maxConcurrentOperations - [self.operationsInProgress count];
        if ([self.reactiveConnections count] > 0) {
            [self.reactiveConnections enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                ReactiveConnectionInfo *info = obj;
                operationsToStart = MIN(operationsToStart, [info.inputs count]);
            }];
        }
    };
    [self safelyExecuteBlock:block];
    return operationsToStart;
}

- (instancetype)clone:(NSMutableDictionary *)objToPointerMapping
{
    __block DFParallelOperation *newParallelOperation = nil;
    dispatch_block_t block = ^(void) {
        newParallelOperation = [super clone:objToPointerMapping];
        newParallelOperation.maxConcurrentOperations = self.maxConcurrentOperations;
        newParallelOperation.outputInOrder = self.outputInOrder;
    };
    [self safelyExecuteBlock:block];
    return newParallelOperation;
}

- (id)copyWithZone:(NSZone *)zone
{
    __block DFParallelOperation *newParallelOperation = nil;
    dispatch_block_t block = ^(void) {
        newParallelOperation = [super copyWithZone:zone];
        newParallelOperation.maxConcurrentOperations = self.maxConcurrentOperations;
        newParallelOperation.outputInOrder = self.outputInOrder;
    };
    [self safelyExecuteBlock:block];
    return newParallelOperation;
}

- (BOOL)isExecutingOperation
{
    return ([self.operationsInProgress count] > 0);
}

- (BOOL)canExecute
{
    BOOL result = NO;
    if ([self isExecuting] && ([self.operationsInProgress count] < self.maxConcurrentOperations)) {
        result = [self isReadyToExecute];
    }
    return result;
}

- (void)operation:(DFOperation *)operation stateChanged:(id)changedValue
{
    dispatch_block_t block = ^(void) {
        if ((self.state == OperationStateDone) || (operation.state != OperationStateDone)) {
            return;
        }
        NSNumber *operationIndex = @(operation.operationIndex);
        //this will remove observation
        NSError *error = operation.error;
        id output = operation.output;
        if (self.outputInOrder) {
            //produce output in order
            NSArray *keys = [[self.operationsInProgress allKeys] sortedArrayUsingSelector:@selector(compare:)];
            [keys enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                NSNumber *key = obj;
                ConnectionInfo *info = self.operationsInProgress[key];
                DFOperation *executingOperation = info.operation;
                if (executingOperation.state == OperationStateDone) {
                    self.error = executingOperation.error;
                    self.output = executingOperation.output;
                    [self.operationsInProgress removeObjectForKey:key];
                }
                else {
                    *stop = YES;
                }
            }];
        }
        else {
            self.error = error;
            self.output = output;
            [self.operationsInProgress removeObjectForKey:operationIndex];
        }
        [self startOperations];
    };
    [self safelyExecuteBlock:block];
}

- (void)startOperation:(DFOperation *)operation
{
    dispatch_block_t block = ^(void) {
        if (!operation) {
            [self done];
            return;
        }
        //prepare operation
        [self prepareOperation:operation];
        [operation setQueuePriorityRecursively:self.queuePriority];
        //start observing
        AMBlockToken *observationToken = [self startObservingOperation:operation];
        OperationInfo *info = [OperationInfo new];
        info.operation = operation;
        info.stateObservationToken = observationToken;
        NSUInteger operationIndex = self.currentOperationIndex;
        //start operation
        [self.operationsInProgress setObject:info forKey:@(operationIndex)];
        operation.operationIndex = operationIndex;
        self.currentOperationIndex = (operationIndex + 1);
        if (self.isSuspended) {
            [operation suspend];
        }
        [operation startExecution];
    };
    [self safelyExecuteBlock:block];
}

- (void)startOperations
{
    //if operation is suspended then return
    if (self.isSuspended) {
        return;
    }
    else if (self.state == OperationStateDone) {
        return;
    }
    //if it's done then mark it as done
    else if ([self isDone]) {
        [self done];
        return;
    }
    else if (![self next]) {
        [self done];
        return;
    }
}

- (BOOL)next
{
    BOOL result = YES;
    if ([self canExecute]) {
        NSUInteger operationsToStart = [self operationsToStart];
        if (operationsToStart > 0) {
            for (int i = 0; i < operationsToStart; i++) {
                if ([self execute]) {
                    self.executionCount ++;
                    [self generateNextValues];
                }
                else {
                    if (self.operationsInProgress.count == 0) {
                        result = NO;
                    }
                    break;
                }
            }
        }
    }
    return result;
}

- (void)suspend
{
    [super suspend];
    dispatch_block_t block = ^(void) {
        [self.operationsInProgress enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            ConnectionInfo *info = obj;
            if (info.operation) {
                [(DFOperation *)info.operation suspend];
            }
        }];
    };
    [self safelyExecuteBlock:block];
}

- (void)resume
{
    [super resume];
    dispatch_block_t block = ^(void) {
        [self.operationsInProgress enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            ConnectionInfo *info = obj;
            if (info.operation) {
                [(DFOperation *)info.operation resume];
            }
        }];
        [self startOperations];
    };
    [self safelyExecuteBlock:block];
}

- (void)cancel
{
    dispatch_block_t block = ^(void) {
        [self.operationsInProgress enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            OperationInfo *info = obj;
            [info clean];
            [info.operation cancelRecursively];
        }];
    };
    [self safelyExecuteBlock:block];
    [super cancel];
}

- (void)main
{
    dispatch_block_t block = ^(void) {
        if (self.state != OperationStateExecuting) {
            return;
        }
        if (self.error) {
            [self done];
        }
        else {
            [self generateNextValues];
            dispatch_queue_t observationQueue = [[self class] operationObservationHandlingQueue];
            @weakify(self);
            dispatch_async(observationQueue, ^{
                @strongify(self);
                if (!self) {
                    return;
                }
                dispatch_block_t block = ^(void) {
                    if ((self.state == OperationStateExecuting) && [self isDone]) {
                        [self done];
                    }
                    else if ([self canExecute]) {
                        [self startOperations];
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
    [self.operationsInProgress removeAllObjects];
}

@end
