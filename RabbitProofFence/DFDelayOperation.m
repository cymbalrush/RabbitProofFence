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
    NSString *reason = [NSString stringWithFormat:@"Method not supported"];
    @throw [NSException exceptionWithName:DFOperationExceptionMethodNotSupported reason:reason userInfo:nil];
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
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)([self.delay doubleValue] * NSEC_PER_SEC)),
                       dispatch_get_main_queue(),
                       block);
        
    }
}

@end
