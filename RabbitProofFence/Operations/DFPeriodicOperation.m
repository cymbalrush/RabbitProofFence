//
//  DFPeriodicOperation.m
//  vf-hollywood
//
//  Created by Sinha, Gyanendra on 6/23/14.
//  Copyright (c) 2014 Conde Nast. All rights reserved.
//

#import "DFPeriodicOperation.h"
#import "DFLoopOperation_SubclassingHooks.h"
#import "DFBackgroundOperation.h"

@interface DFPeriodicOperation ()

@property (assign, nonatomic) NSUInteger DF_scheduledSyncNumber;

@end

@implementation DFPeriodicOperation

+ (instancetype)operationFromBlock:(id)block ports:(NSArray *)ports
{
    DFOperation *operation = [DFBackgroundOperation operationFromBlock:block ports:ports];
    return [[[self class] alloc] initWithOperation:operation andWaitInterval:0];
}

- (instancetype)initWithOperation:(DFOperation *)operation andWaitInterval:(NSTimeInterval)waitInterval
{
    self = [self initWithOperation:operation];
    if (self) {
        self.waitInterval = waitInterval;
    }
    return self;
}

- (instancetype)DF_clone:(NSMutableDictionary *)objToPointerMapping
{
    __block DFPeriodicOperation *newPeriodicOperation = nil;
    dispatch_block_t block = ^(void) {
        newPeriodicOperation = [super DF_clone:objToPointerMapping];
        newPeriodicOperation.waitInterval = self.waitInterval;
    };
    [self DF_safelyExecuteBlock:block];
    return newPeriodicOperation;
}

- (instancetype)copyWithZone:(NSZone *)zone
{
    __block DFPeriodicOperation *newPeriodicOperation = nil;
    dispatch_block_t block = ^(void) {
        newPeriodicOperation = [super copyWithZone:zone];
        newPeriodicOperation.waitInterval = self.waitInterval;
    };
    [self DF_safelyExecuteBlock:block];
    return newPeriodicOperation;
}

- (void)DF_operation:(DFOperation *)operation stateChanged:(id)changedValue
{
    dispatch_block_t block = ^(void) {
        OperationState state = [changedValue integerValue];
        if ((self.DF_state == OperationStateDone) || (state != OperationStateDone)) {
            return;
        }
        self.DF_runningOperationInfo = nil;
        NSError *error = operation.DF_error;
        if (error) {
            self.DF_error = error;
            self.DF_output = errorObject(error);
            [self DF_done];
            return;
        }
        else {
            self.DF_output = operation.DF_output;
        }
        self.DF_scheduledSyncNumber ++;
        NSUInteger scheduledSyncNumber = self.DF_scheduledSyncNumber;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, self.waitInterval * NSEC_PER_SEC);
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        @weakify(self);
        NSLog(@"Starting next %@ in %f seconds", NSStringFromClass([self class]), self.waitInterval);
        dispatch_after(popTime, queue, ^{
            @strongify(self);
            if (!self) {
                return;
            }
            dispatch_block_t block = ^(void) {
                if (self.DF_state == OperationStateExecuting && (scheduledSyncNumber == self.DF_scheduledSyncNumber)) {
                    if (![self DF_next]) {
                        [self DF_done];
                    }
                }
            };
            [self DF_safelyExecuteBlock:block];
        });
    };
    [self DF_safelyExecuteBlock:block];
}

- (void)setWaitIntervalAndStartNow:(NSTimeInterval)waitInterval
{
    dispatch_block_t block = ^(void) {
        _waitInterval = waitInterval;
        self.DF_scheduledSyncNumber ++;
        NSUInteger scheduledSyncNumber = self.DF_scheduledSyncNumber;
        @weakify(self);
        dispatch_queue_t operationStartQueue = [[self class] DF_startQueue];
        dispatch_async(operationStartQueue, ^(void){
            @strongify(self);
            dispatch_block_t block = ^(void) {
                if ((self.DF_state == OperationStateExecuting) &&
                    !self.DF_isExecutingOperation &&
                    (scheduledSyncNumber == self.DF_scheduledSyncNumber)) {
                    if (![self DF_next]) {
                        [self DF_done];
                    }
                }
            };
            [self DF_safelyExecuteBlock:block];
            
        });
    };
    [self DF_safelyExecuteBlock:block];
}

@end
