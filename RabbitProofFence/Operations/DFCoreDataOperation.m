//
//  DFCoreDataOperation.m
//  vf-hollywood
//
//  Created by Sinha, Gyanendra on 6/23/14.
//  Copyright (c) 2014 Conde Nast. All rights reserved.
//

#import "DFCoreDataOperation.h"
#import "DFOperation_SubclassingHooks.h"

NSString * const DFCoreDataOperationQueueName = @"com.operations.coreDataQueue";

@implementation DFCoreDataOperation

+ (NSOperationQueue *)operationQueue
{
    static NSOperationQueue *queue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = [[NSOperationQueue alloc] init];
        queue.name = DFCoreDataOperationQueueName;
        //we need a queue for prioritizing operations
        [queue setMaxConcurrentOperationCount:1];
    });
    return queue;
}
    
- (instancetype)DF_clone:(NSMutableDictionary *)objToPointerMapping
{
    __block DFCoreDataOperation *newCoreDataOperation = nil;
    dispatch_block_t block = ^() {
        newCoreDataOperation = [super DF_clone:objToPointerMapping];
        newCoreDataOperation.context = self.context;
    };
    [self DF_safelyExecuteBlock:block];
    return newCoreDataOperation;
}

- (instancetype)copyWithZone:(NSZone *)zone
{
    __block DFCoreDataOperation *newCoreDataOperation = nil;
    dispatch_block_t block = ^() {
        newCoreDataOperation = [super copyWithZone:zone];
        newCoreDataOperation.context = self.context;
    };
    [self DF_safelyExecuteBlock:block];
    return newCoreDataOperation;
}

- (void)main
{
    dispatch_block_t block = ^(void) {
        if (self.DF_state != OperationStateExecuting) {
            return;
        }
        if (self.context) {
            @weakify(self);
            [self.context performBlock:^{
                @strongify(self);
                if (!self) {
                    return;
                }
                else if (self.DF_state == OperationStateDone) {
                    return;
                }
                else if (self.isCancelled) {
                    dispatch_block_t block = ^(void) {
                        if (self.DF_state == OperationStateExecuting) {
                            [self DF_done];
                        }
                    };
                    [self DF_safelyExecuteBlock:block];
                }
                else {
                    [self DF_execute];
                }
            }];
        }
        else {
            [self DF_done];
        }
    };
    [self DF_safelyExecuteBlock:block];
}

@end
