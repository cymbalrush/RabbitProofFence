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
            [self DF_addPortToInputPorts:port];
            [self DF_setType:[EXTNil null] forPort:port];
        }];
        [self DF_setType:[NSArray class] forPort:@keypath(self.DF_output)];
    }
    return self;
}

- (BOOL)DF_execute
{
    if ([self.DF_executionObj numberOfPorts] == 0) {
        return NO;
    }
    [self DF_prepareExecutionObj:self.DF_executionObj];
    NSArray *valuesArray = [self.DF_executionObj valuesArray];
    self.DF_output = valuesArray;
    [self DF_breakRefCycleForExecutionObj:self.DF_executionObj];
    return YES;
}

- (BOOL)DF_next
{
    BOOL result = YES;
    while ([self DF_canExecute]) {
        result = [super DF_next];
        if (!result) {
            break;
        }
    }
    if ([self DF_isDone]) {
        result = NO;
    }
    return result;
}

@end
