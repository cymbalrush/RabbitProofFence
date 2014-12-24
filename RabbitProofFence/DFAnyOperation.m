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
            [self addPortToInputPorts:port];
        }];
    }
    return self;
}

- (BOOL)isDone
{
    __block BOOL result = YES;
    dispatch_block_t block = ^(void) {
        if (self.state == OperationStateReady) {
            result = NO;
        }
        else if (self.state == OperationStateExecuting) {
            [self.reactiveConnections enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                ReactiveConnectionInfo *info = obj;
                if (!(info.operationState == OperationStateDone && [info.inputs count] == 0)) {
                    result = NO;
                    *stop = YES;
                }
            }];
        }
    };
    [self safelyExecuteBlock:block];
    return result;
}

- (BOOL)canExecute
{
    __block BOOL result = NO;
    dispatch_block_t block = ^(void) {
        if (self.state == OperationStateExecuting) {
            [self.reactiveConnections enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                ReactiveConnectionInfo *info = obj;
                if ([info.inputs count] > 0){
                    result = YES;
                    *stop = YES;
                }
            }];
        }
    };
    [self safelyExecuteBlock:block];
    return result;
}

- (BOOL)retry
{
    __block BOOL result = NO;
    dispatch_block_t block = ^(void) {
        [self.inputPorts enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSString *property = obj;
            ReactiveConnectionInfo *info = self.reactiveConnections[property];
            if ([info.inputs count] > 0) {
                result = YES;
                id output = info.inputs[0];
                [info.inputs removeObjectAtIndex:0];
                self.output = output;
            }
        }];
    };
    [self safelyExecuteBlock:block];
    return result;
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
