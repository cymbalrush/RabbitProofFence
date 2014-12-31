//
//  DFDropOperation.m
//  RabbitProofFence
//
//  Created by Sinha, Gyanendra on 12/30/14.
//  Copyright (c) 2014 Sinha, Gyanendra. All rights reserved.
//

#import "DFDropOperation.h"
#import "DFReactiveOperation_SubclassingHooks.h"

@interface DFDropOperation ()

@property (assign, nonatomic) NSInteger i;

@end

@implementation DFDropOperation

- (instancetype)init
{
    return [super initWithMapBlock:^(id input, NSNumber *n) {
        return input;
    } ports:@[@keypath(self.input), @keypath(self.n)]];
}

- (BOOL)retry
{
    Execution_Class *executionObj = self.executionObj;
    if (executionObj.executionBlock) {
        [self prepareExecutionObj:executionObj];
        @try {
            id output = [executionObj execute];
            if (self.i > 0) {
                self.output = output;
                self.i --;
            }
        }
        @catch (NSException *exception) {
            self.error = NSErrorFromException(exception);
        }
        @finally {
            [self breakRefCycleForExecutionObj:self.executionObj];
        }
        if (!self.error) {
            return YES;
        }
    }
    return NO;
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
