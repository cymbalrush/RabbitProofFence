//
//  DFAnyOperation.m
//  vf-hollywood
//
//  Created by Sinha, Gyanendra on 6/23/14.
//  Copyright (c) 2014 Conde Nast. All rights reserved.
//

#import "DFAnyOperation.h"
#import "DFReactiveOperation_SubclassingHooks.h"

@implementation DFAnyOperation

+ (instancetype)anyOperation:(NSArray *)ports
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
        }];
    }
    return self;
}

- (BOOL)DF_isDone
{
    __block BOOL result = NO;
    if (self.DF_state == OperationStateDone) {
        result = YES;
    }
    else if (self.DF_state == OperationStateExecuting) {
        __block BOOL done = (self.DF_executionCount > 0);
        [self.DF_reactiveConnections enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            ReactiveConnectionInfo *info = obj;
            if (!(info.operationState == OperationStateDone && [info.inputs count] == 0)) {
                done = NO;
                *stop = YES;
            }
        }];
        result = done;
    }
    return result;
}

- (BOOL)DF_canExecute
{
    __block BOOL result = (self.DF_executionCount == 0);
    if (self.DF_state == OperationStateExecuting) {
        [self.DF_reactiveConnections enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            ReactiveConnectionInfo *info = obj;
            if ([info.inputs count] > 0){
                result = YES;
                *stop = YES;
            }
        }];
    }
    return result;
}

- (BOOL)DF_execute
{
    __block BOOL result = NO;
    [self.DF_inputPorts enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSString *property = obj;
        ReactiveConnectionInfo *info = self.DF_reactiveConnections[property];
        if (info.inputs.count > 0) {
            result = YES;
            id output = info.inputs[0];
            [info.inputs removeObjectAtIndex:0];
            self.DF_output = output;
        }
    }];
    return result;
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
