//
//  DFBufferOperation.m
//  RabbitProofFence
//
//  Created by Sinha, Gyanendra on 1/5/15.
//  Copyright (c) 2015 Sinha, Gyanendra. All rights reserved.
//

#import "DFBufferOperation.h"
#import "DFReactiveOperation_SubclassingHooks.h"

@interface DFBufferOperation ()

@property (strong, nonatomic) NSMutableArray *DF_buffer;

@end

@implementation DFBufferOperation

- (instancetype)init
{
    self = [super initWithMapBlock:^(id input, NSNumber *n, DFBufferOperation *selfRef) {
        input = (input == nil) ? [EXTNil null] : input;
        if (n.integerValue > 0) {
            if (selfRef.DF_buffer.count <= n.integerValue) {
                [selfRef.DF_buffer addObject:input];
            }
        }
        else {
            if (selfRef.DF_buffer.count  > -n.integerValue) {
                [selfRef.DF_buffer removeObjectAtIndex:0];
                [selfRef.DF_buffer addObject:input];
            }
            else {
                [selfRef.DF_buffer addObject:input];
            }
        }
        return input;
    } ports:@[@keypath(self.input), @keypath(self.n)]];
    if (self) {
        self.DF_buffer = [NSMutableArray new];
    }
    return self;
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
    if (self.n.integerValue == 0) {
        return NO;
    }
    BOOL result = YES;
    NSError *error = nil;
    Execution_Class *executionObj = self.DF_executionObj;
    @try {
        [self DF_prepareExecutionObj:executionObj];
        [executionObj execute];
        if (self.n.integerValue > 0 && (self.DF_buffer.count == self.n.integerValue)) {
            return NO;
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

- (void)DF_done
{
    if (!self.DF_error) {
        self.DF_output = self.DF_buffer;
    }
    [super DF_done];
}

@end
