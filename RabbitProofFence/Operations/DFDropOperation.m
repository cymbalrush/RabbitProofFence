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

@property (strong, nonatomic) NSNumber *DF_counter;

@end

@implementation DFDropOperation

- (instancetype)init
{
    return [super initWithMapBlock:^(id input, NSNumber *n) {
        return input;
    } ports:@[@keypath(self.input), @keypath(self.n)]];
}

- (Class)portType:(NSString *)port
{
    __block Class type = nil;
    dispatch_block_t block = ^(void) {
        type = [super portType:port];
        if ([port isEqualToString:@keypath(self.DF_output)] || [port isEqualToString:@keypath(self.output)]) {
            type = [super portType:@keypath(self.input)];
        }
    };
    [self DF_safelyExecuteBlock:block];
    return type;
}

- (BOOL)DF_execute
{
    BOOL result = YES;
    NSError *error = nil;
    Execution_Class *executionObj = self.DF_executionObj;
    @try {
        NSInteger i = [self.DF_counter integerValue];
        if (i > 0) {
            i --;
            self.DF_counter = @(i);
        }
        else {
            [self DF_prepareExecutionObj:executionObj];
            id output = [executionObj execute];
            self.DF_output = output;
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
        [super main];
    };
    [self DF_safelyExecuteBlock:block];
}

@end
