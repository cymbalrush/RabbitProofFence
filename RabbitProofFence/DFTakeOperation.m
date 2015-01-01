//
//  DFTakeOperation.m
//  RabbitProofFence
//
//  Created by Sinha, Gyanendra on 12/30/14.
//  Copyright (c) 2014 Sinha, Gyanendra. All rights reserved.
//

#import "DFTakeOperation.h"
#import "DFReactiveOperation_SubclassingHooks.h"

@interface DFTakeOperation ()

@property (assign, nonatomic) NSInteger i;

@end

@implementation DFTakeOperation

- (instancetype)init
{
    return [super initWithMapBlock:^(id input, NSNumber *n) {
        return input;
    } ports:@[@keypath(self.input), @keypath(self.n)]];
}

- (BOOL)next
{
    BOOL result = YES;
    while ([self canExecute] && self.i > 0) {
        self.i --;
        result = [super next];
        if (!result) {
            break;
        }
    }
    if ([self isDone] || self.i == 0) {
        result = NO;
    }
    return result;
}

- (void)main
{
    dispatch_block_t block = ^(void) {
        if (self.state != OperationStateExecuting) {
            return;
        }
        self.i = [self.n integerValue];
        [super main];
    };
    [self safelyExecuteBlock:block];
}

@end
