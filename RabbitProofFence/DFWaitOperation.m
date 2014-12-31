//
//  DFWaitOperation.m
//  vf-hollywood
//
//  Created by Sinha, Gyanendra on 6/23/14.
//  Copyright (c) 2014 Conde Nast. All rights reserved.
//

#import "DFWaitOperation.h"
#import "DFMetaOperation_SubclassingHooks.h"
#import "DFBackgroundOperation.h"

@implementation DFWaitOperation

+ (instancetype)operationFromBlock:(id)block ports:(NSArray *)ports
{
    DFOperation *operation = [DFBackgroundOperation operationFromBlock:block ports:ports];
    return [[[self class] alloc] initWithOperation:operation andWaitInterval:0];
}

- (instancetype)initWithOperation:(DFOperation *)operation andWaitInterval:(NSTimeInterval)waitInterval
{
    self = [super initWithOperation:operation];
    if (self) {
        self.waitInterval = waitInterval;
    }
    return self;
}

- (instancetype)clone:(NSMutableDictionary *)objToPointerMapping
{
    __block DFWaitOperation *newWaitOperation = nil;
    dispatch_block_t block = ^(void) {
        newWaitOperation = [super clone:objToPointerMapping];
        newWaitOperation.waitInterval = self.waitInterval;
    };
    [self safelyExecuteBlock:block];
    return newWaitOperation;
}

- (instancetype)copyWithZone:(NSZone *)zone
{
    __block DFWaitOperation *newWaitOperation = nil;
    dispatch_block_t block = ^(void) {
        newWaitOperation = [super copyWithZone:zone];
        newWaitOperation.waitInterval = self.waitInterval;
    };
    [self safelyExecuteBlock:block];
    return newWaitOperation;
}

- (void)main
{
    dispatch_block_t block = ^(void) {
        if (self.state != OperationStateExecuting) {
            return;
        }
        if (!self.error) {
            if (self.waitInterval == 0) {
                [self startOperation:self.operation];
                return;
            }
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, self.waitInterval * NSEC_PER_SEC);
            dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
            @weakify(self);
            dispatch_after(popTime, queue, ^{
                @strongify(self);
                dispatch_block_t block = ^(void) {
                    if (self.state == OperationStateExecuting) {
                        [self startOperation:self.operation];
                    }
                };
                [self safelyExecuteBlock:block];
            });
            return;
        }
        self.output = [DFVoidObject new];
        [self done];
    };
    [self safelyExecuteBlock:block];
}

@end
