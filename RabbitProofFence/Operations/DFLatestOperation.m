//
//  DFLatestOperation.m
//  FBP
//
//  Created by Sinha, Gyanendra on 1/7/15.
//  Copyright (c) 2015 Sinha, Gyanendra. All rights reserved.
//

#import "DFLatestOperation.h"
#import "DFReactiveOperation_SubclassingHooks.h"

@interface LatestConnectionInfo : ReactiveConnection

@end

@implementation LatestConnectionInfo

- (void)addInput:(id)input
{
    input = (input == nil) ? [EXTNil null] : input;
    [self.inputs insertObject:input atIndex:0];
    if (self.connectionCapacity > -1) {
        NSInteger itemsToRemove = self.inputs.count - self.connectionCapacity;
        if (itemsToRemove > 0) {
            NSRange range = NSMakeRange(self.inputs.count - itemsToRemove, itemsToRemove);
            [self.inputs removeObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:range]];
        }
    }
}

@end

@implementation DFLatestOperation

- (instancetype)init
{
    self = [super initWithMapBlock:^(id input, NSNumber *bufferCapacity) {
        return input;
    } ports:@[@keypath(self.input), @keypath(self.bufferLimit)]];
    self.bufferLimit = @(1);
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

- (ReactiveConnection *)DF_newReactiveConnection
{
    return [LatestConnectionInfo new];
}

- (BOOL)DF_canExecute
{
    __block BOOL result = (self.DF_executionCount == 0);
    if (self.DF_state == OperationStateExecuting) {
        result = (self.DF_reactiveConnections.count > 0) ? NO : result;
        [self.DF_reactiveConnections enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            ReactiveConnection *info = obj;
            if (info.operationState == OperationStateExecuting) {
                result = (info.inputs.count >= self.bufferLimit.integerValue);
            }
            else if (info.operationState == OperationStateDone) {
                result = YES;
            }
            else {
                result = NO;
            }
            if (result == NO) {
                *stop = YES;
            }
        }];
    }
    return result;
}

@end
