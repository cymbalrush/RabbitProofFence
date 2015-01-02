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

@property (assign, nonatomic) NSUInteger scheduledSyncNumber;

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

- (instancetype)clone:(NSMutableDictionary *)objToPointerMapping
{
    __block DFPeriodicOperation *newPeriodicOperation = nil;
    dispatch_block_t block = ^(void) {
        newPeriodicOperation = [super clone:objToPointerMapping];
        newPeriodicOperation.waitInterval = self.waitInterval;
    };
    [self safelyExecuteBlock:block];
    return newPeriodicOperation;
}

- (instancetype)copyWithZone:(NSZone *)zone
{
    __block DFPeriodicOperation *newPeriodicOperation = nil;
    dispatch_block_t block = ^(void) {
        newPeriodicOperation = [super copyWithZone:zone];
        newPeriodicOperation.waitInterval = self.waitInterval;
    };
    [self safelyExecuteBlock:block];
    return newPeriodicOperation;
}

- (void)operation:(DFOperation *)operation stateChanged:(id)changedValue
{
    dispatch_block_t block = ^(void) {
        if ((self.state == OperationStateDone) || (operation.state != OperationStateDone)) {
            return;
        }
        //remove observation token
        self.error = operation.error;
        self.output = operation.output;
        self.executingOperationInfo = nil;
        self.scheduledSyncNumber ++;
        NSUInteger scheduledSyncNumber = self.scheduledSyncNumber;
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
                if (self.state == OperationStateExecuting && (scheduledSyncNumber == self.scheduledSyncNumber)) {
                    if (![self execute]) {
                        [self done];
                    }
                }
            };
            [self safelyExecuteBlock:block];
        });
    };
    [self safelyExecuteBlock:block];
}

- (void)setWaitIntervalAndStartNow:(NSTimeInterval)waitInterval
{
    dispatch_block_t block = ^(void) {
        _waitInterval = waitInterval;
        self.scheduledSyncNumber ++;
        NSUInteger scheduledSyncNumber = self.scheduledSyncNumber;
        @weakify(self);
        dispatch_queue_t operationStartQueue = [[self class] operationStartQueue];
        dispatch_async(operationStartQueue, ^(void){
            @strongify(self);
            dispatch_block_t block = ^(void) {
                if ((self.state == OperationStateExecuting) &&
                    !self.isExecutingOperation &&
                    (scheduledSyncNumber == self.scheduledSyncNumber)) {
                    if (![self execute]) {
                        [self done];
                    }
                }
            };
            [self safelyExecuteBlock:block];
            
        });
    };
    [self safelyExecuteBlock:block];
}

@end
