//
//  DFWaitOperation.m
//  vf-hollywood
//
//  Created by Sinha, Gyanendra on 6/23/14.
//  Copyright (c) 2014 Conde Nast. All rights reserved.
//

#import "DFDelayOperation.h"
#import "DFOperation_SubclassingHooks.h"

@implementation DFDelayOperation

+ (instancetype)operationFromBlock:(id)block ports:(NSArray *)ports
{
    methodNotSupported();
    return nil;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.inputPorts = @[@keypath(self.input), @keypath(self.delay)];
        self.executionBlock = ^(id input, NSNumber *delay) {
            return input;
        };
    }
    return self;
}

- (void)main
{
    if ([self.delay doubleValue] == 0) {
        [self execute];
    }
    else {
        @weakify(self);
        dispatch_block_t block = ^(void) {
            @strongify(self);
            [self execute];
            
        };
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)([self.delay doubleValue] * NSEC_PER_SEC)), queue, block);
    }
}

@end
