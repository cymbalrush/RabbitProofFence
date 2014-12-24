//
//  DFAndOperation.m
//  vf-hollywood
//
//  Created by Sinha, Gyanendra on 6/23/14.
//  Copyright (c) 2014 Conde Nast. All rights reserved.
//

#import "DFAndOperation.h"
#import "DFReactiveOperation_SubclassingHooks.h"

@implementation DFAndOperation

+ (instancetype)andOperation:(NSArray *)ports
{
    return [[self alloc] initWithPorts:ports];
}

- (instancetype)initWithPorts:(NSArray *)ports
{
    self = [super init];
    if (self) {
        [ports enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSString *port = obj;
            [self addPortToInputPorts:port];
        }];
    }
    return self;
}

- (BOOL)retry
{
    if ([self.executionObj numberOfPorts] == 0) {
        return NO;
    }
    [self prepareExecutionObj:self.executionObj];
    NSArray *valuesArray = [self.executionObj valuesArray];
    self.output = valuesArray;
    return YES;
}

- (BOOL)next
{
    __block BOOL result = YES;
    dispatch_block_t block = ^(void) {
        while ([self canExecute]) {
            result = [super next];
            if (!result) {
                break;
            }
        }
        if ([self isDone]) {
            result = NO;
        }
    };
    [self safelyExecuteBlock:block];
    return result;
}

@end
