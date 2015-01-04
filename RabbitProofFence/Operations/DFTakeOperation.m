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

@property (strong, nonatomic) NSNumber *DF_counter;

@end

@implementation DFTakeOperation

- (instancetype)init
{
    return [super initWithMapBlock:^(id input, NSNumber *n) {
        return input;
    } ports:@[@keypath(self.input), @keypath(self.n)]];
}

- (BOOL)DF_execute
{
    BOOL result = YES;
    NSError *error = nil;
    Execution_Class *executionObj = self.DF_executionObj;
    @try {
        NSInteger i = [self.DF_counter integerValue];
        if (i <= 0) {
            result = NO;
        }
        else {
            [self DF_prepareExecutionObj:executionObj];
            id output = [executionObj execute];
            self.DF_output = output;
            i --;
            self.DF_counter = @(i);
        }
    }
    @catch (NSException *exception) {
        error = NSErrorFromException(exception);
        self.DF_error = error;
        self.DF_output = errorObject(error);
        result = NO;
    }
    @finally {
        [self DF_breakRefCycleForExecutionObj:self.DF_executionObj];
    }
    return result;
}

- (void)main
{
    dispatch_block_t block = ^(void) {
        self.DF_counter = self.n;
    };
    [self DF_safelyExecuteBlock:block];
}

@end
