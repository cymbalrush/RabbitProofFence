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

static char const * const OPERATION_INDEX_KEY = "com.operations.DF_operationIndexKey";

@interface DFOperation (Parallel)

@property (assign, nonatomic) NSUInteger DF_operationIndex;

@end

@implementation DFOperation (Parallel)

- (NSUInteger)DF_operationIndex
{
    return [objc_getAssociatedObject(self, OPERATION_INDEX_KEY) intValue];
}

- (void)setDF_operationIndex:(NSUInteger)operationIndex
{
    objc_setAssociatedObject(self, OPERATION_INDEX_KEY, @(operationIndex), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

@interface DFParallelOperation ()

@property (nonatomic, strong) NSMutableDictionary *DF_operationsInProgress;

@property (assign, nonatomic) NSUInteger DF_currentOperationIndex;

@end

@implementation DFParallelOperation

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.DF_operationsInProgress = [NSMutableDictionary dictionary];
        self.maxConcurrentOperations = 1;
        self.outputInOrder = YES;
        self.DF_currentOperationIndex = 0;
    }
    return self;
}

- (NSUInteger)DF_operationsToStart
{
   __block NSUInteger operationsToStart = 0;
    dispatch_block_t block = ^(void) {
        operationsToStart = self.maxConcurrentOperations - [self.DF_operationsInProgress count];
        if ([self.DF_reactiveConnections count] > 0) {
            [self.DF_reactiveConnections enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                ReactiveConnectionInfo *info = obj;
                operationsToStart = MIN(operationsToStart, [info.inputs count]);
            }];
        }
    };
    [self DF_safelyExecuteBlock:block];
    return operationsToStart;
}

- (instancetype)DF_clone:(NSMutableDictionary *)objToPointerMapping
{
    __block DFParallelOperation *newParallelOperation = nil;
    dispatch_block_t block = ^(void) {
        newParallelOperation = [super DF_clone:objToPointerMapping];
        newParallelOperation.maxConcurrentOperations = self.maxConcurrentOperations;
        newParallelOperation.outputInOrder = self.outputInOrder;
    };
    [self DF_safelyExecuteBlock:block];
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
    [self DF_safelyExecuteBlock:block];
    return newParallelOperation;
}

- (BOOL)DF_isExecutingOperation
{
    return ([self.DF_operationsInProgress count] > 0);
}

- (BOOL)DF_canExecute
{
    BOOL result = NO;
    if ([self isExecuting] &&
        self.DF_operationsInProgress &&
        [self.DF_operationsInProgress count] < self.maxConcurrentOperations) {
        result = [self DF_isReadyToExecute];
    }
    return result;
}

- (void)DF_operation:(DFOperation *)operation stateChanged:(id)changedValue
{
    __block NSDictionary *operationsToCancel = nil;
    dispatch_block_t block = ^(void) {
        if (self.DF_state == OperationStateDone || !self.DF_operationsInProgress) {
            return;
        }
        NSNumber *operationIndex = @(operation.DF_operationIndex);
        OperationInfo *info  = self.DF_operationsInProgress[operationIndex];
        OperationState state = [changedValue integerValue];
        info.operationState = state;
        if (!info || state != OperationStateDone) {
            return;
        }
        NSError *error = operation.DF_error;
        if (error) {
            //done
            self.DF_error = error;
            self.DF_output = errorObject(error);
            [self.DF_operationsInProgress enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                OperationInfo *info = obj;
                [info clean];
            }];
            operationsToCancel = [self.DF_operationsInProgress copy];
            [self DF_done];
            self.DF_operationsInProgress = nil;
        }
        else {
            if (self.outputInOrder) {
                //produce output in order
                NSArray *keys = [[self.DF_operationsInProgress allKeys] sortedArrayUsingSelector:@selector(compare:)];
                [keys enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                    NSNumber *key = obj;
                    OperationInfo *info = self.DF_operationsInProgress[key];
                    DFOperation *operation = info.operation;
                    if (info.operationState == OperationStateDone) {
                        self.DF_output = operation.output;
                        [self.DF_operationsInProgress removeObjectForKey:key];
                    }
                    else {
                        *stop = YES;
                    }
                }];
            }
            else {
                self.DF_output = operation.output;
                [self.DF_operationsInProgress removeObjectForKey:operationIndex];
            }
            [self DF_startOperations];
        }
    };
    [self DF_safelyExecuteBlock:block];
    [operationsToCancel enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        OperationInfo *info = obj;
        [info.operation cancelRecursively];
    }];
}

- (void)DF_startOperation:(DFOperation *)operation
{
    dispatch_block_t block = ^(void) {
        if (!operation) {
            [self DF_done];
            return;
        }
        //prepare operation
        [self DF_prepareOperation:operation];
        [operation setQueuePriorityRecursively:self.queuePriority];
        //start observing
        AMBlockToken *observationToken = [self DF_startObservingOperation:operation];
        OperationInfo *info = [OperationInfo new];
        info.operation = operation;
        info.stateObservationToken = observationToken;
        NSUInteger operationIndex = self.DF_currentOperationIndex;
        //start operation
        [self.DF_operationsInProgress setObject:info forKey:@(operationIndex)];
        operation.DF_operationIndex = operationIndex;
        self.DF_currentOperationIndex = (operationIndex + 1);
        if (self.DF_isSuspended) {
            [operation suspend];
        }
        [operation startExecution];
    };
    [self DF_safelyExecuteBlock:block];
}

- (void)DF_startOperations
{
    //if operation is suspended then return
    if (self.DF_isSuspended || !self.DF_operationsInProgress) {
        return;
    }
    else if (self.DF_state == OperationStateDone) {
        return;
    }
    //if it's done then mark it as done
    else if ([self DF_isDone]) {
        [self DF_done];
        return;
    }
    else if (![self DF_next]) {
        [self DF_done];
        return;
    }
}

- (BOOL)DF_next
{
    BOOL result = YES;
    if ([self DF_canExecute]) {
        NSUInteger operationsToStart = [self DF_operationsToStart];
        if (operationsToStart > 0) {
            for (int i = 0; i < operationsToStart; i++) {
                if ([self DF_execute]) {
                    self.DF_executionCount ++;
                    [self DF_generateNextValues];
                }
                else {
                    if (self.DF_operationsInProgress.count == 0) {
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
        [self.DF_operationsInProgress enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            OperationInfo *info = obj;
            if (info.operation) {
                [info.operation suspend];
            }
        }];
    };
    [self DF_safelyExecuteBlock:block];
}

- (void)resume
{
    [super resume];
    dispatch_block_t block = ^(void) {
        [self.DF_operationsInProgress enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            OperationInfo *info = obj;
            if (info.operation) {
                [info.operation resume];
            }
        }];
        [self DF_startOperations];
    };
    [self DF_safelyExecuteBlock:block];
}


- (void)cancel
{
    __block NSMutableDictionary *operationsInProgress = nil;
    dispatch_block_t block = ^(void) {
        [self.DF_operationsInProgress enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            OperationInfo *info = obj;
            [info clean];
        }];
        operationsInProgress = [self.DF_operationsInProgress copy];
        self.DF_operationsInProgress = nil;
    };
    [self DF_safelyExecuteBlock:block];
    [super cancel];
    [operationsInProgress enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        OperationInfo *info = obj;
        [info.operation cancelRecursively];
    }];
}

- (void)main
{
    dispatch_block_t block = ^(void) {
        if (self.DF_state != OperationStateExecuting) {
            return;
        }
        [self DF_generateNextValues];
        dispatch_queue_t observationQueue = [[self class] DF_observationQueue];
        @weakify(self);
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
                    [self DF_startOperations];
                }
            };
            [self DF_safelyExecuteBlock:block];
        });
    };
    [self DF_safelyExecuteBlock:block];
}

- (void)DF_done
{
    [super DF_done];
    [self.DF_operationsInProgress removeAllObjects];
}

@end
