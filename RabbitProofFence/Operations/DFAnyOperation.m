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
            [self DF_setType:[EXTNil null] forPort:port];
        }];
        [self DF_setType:[EXTNil null] forPort:@keypath(self.DF_output)];
    }
    return self;
}

- (BOOL)canConnectPort:(NSString *)port ofOperation:(DFOperation *)operation toPort:(NSString *)toPort
{
    if ([super canConnectPort:port ofOperation:operation toPort:toPort]) {
        Class fromType = [operation portType:port];
        NSArray *inputPorts = self.inputPorts;
        __block BOOL result = YES;
        [inputPorts enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSString *port = obj;
            Class type = [self portType:port];
            if (type != [EXTNil null]) {
                result = [fromType isSubclassOfClass:type];
                *stop = YES;
            }
        }];
        return result;
    }
    return NO;
}

- (Class)portType:(NSString *)port
{
    __block Class type = nil;
    dispatch_block_t block = ^(void) {
        type = [super portType:port];
        if ([port isEqualToString:@keypath(self.DF_output)] || [port isEqualToString:@keypath(self.output)]) {
            type = [self portType:[self.inputPorts firstObject]];
        }
    };
    [self DF_safelyExecuteBlock:block];
    return type;
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
            done = (info.operationState == OperationStateDone && info.inputs.count == 0);
            if (!done) {
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
        result = (self.DF_reactiveConnections.count > 0) ? NO : result;
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

- (NSDictionary *)addReactiveDependency:(DFOperation *)operation withBindings:(NSDictionary *)bindings
{
    NSDictionary *dict = [super addReactiveDependency:operation withBindings:bindings];
    return dict;
}

- (BOOL)DF_execute
{
    __block BOOL result = NO;
    [self.DF_inputPorts enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSString *port = obj;
        ReactiveConnectionInfo *info = self.DF_reactiveConnections[port];
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
