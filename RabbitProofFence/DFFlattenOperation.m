//
//  DFSplitterOperation.m
//  vf-hollywood
//
//  Created by Sinha, Gyanendra on 8/1/14.
//  Copyright (c) 2014 Conde Nast. All rights reserved.
//

#import "DFFlattenOperation.h"
#import "DFReactiveOperation_SubclassingHooks.h"

@interface FlattenInputInfo : ReactiveConnectionInfo

@end

@implementation FlattenInputInfo

- (void)addInput:(id)input
{
    if ([input isKindOfClass:[NSArray class]]) {
        [input enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [super addInput:obj];
        }];
    }
    else {
        [super addInput:input];
    }
}

@end

@implementation DFFlattenOperation

+ (instancetype)operationFromBlock:(id)block ports:(NSArray *)ports
{
    NSString *reason = [NSString stringWithFormat:@"Method not supported"];
    @throw [NSException exceptionWithName:DFOperationExceptionMethodNotSupported reason:reason userInfo:nil];
}

- (instancetype)initWithOperation:(DFOperation *)operation
{
    NSString *reason = [NSString stringWithFormat:@"Method not supported"];
    @throw [NSException exceptionWithName:DFOperationExceptionMethodNotSupported reason:reason userInfo:nil];
}

- (instancetype)initWithRetryBlock:(id)retryBlock ports:(NSArray *)ports
{
    NSString *reason = [NSString stringWithFormat:@"Method not supported"];
    @throw [NSException exceptionWithName:DFOperationExceptionMethodNotSupported reason:reason userInfo:nil];
}

- (instancetype)initWithMapBlock:(id)mapBlock ports:(NSArray *)ports
{
    NSString *reason = [NSString stringWithFormat:@"Method not supported"];
    @throw [NSException exceptionWithName:DFOperationExceptionMethodNotSupported reason:reason userInfo:nil];
}

+ (instancetype)flattenOperation
{
    return [DFFlattenOperation new];
}

- (instancetype)init
{
    id (^mapBlock)(id input) = ^(id input) {
        return input;
    };
    return [super initWithMapBlock:mapBlock ports:@[@keypath(self.input)]];
}

- (ReactiveConnectionInfo *)newInfo
{
    return [FlattenInputInfo new];
}

- (void)connectWithOperation:(DFOperation *)operation
{
    [self connectPortReactively:@keypath(self.input) toOutputOfOperation:operation];
}

@end
