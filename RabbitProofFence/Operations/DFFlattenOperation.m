//
//  DFSplitterOperation.m

//
//  Created by Sinha, Gyanendra on 8/1/14.

//

#import "DFFlattenOperation.h"
#import "DFReactiveOperation_SubclassingHooks.h"

@interface SplitConnectionInfo : ReactiveConnection

@end

@implementation SplitConnectionInfo

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
    methodNotSupported();
    return nil;
}

- (instancetype)initWithOperation:(DFOperation *)operation
{
    methodNotSupported();
    return nil;
}

- (instancetype)initWithRetryBlock:(id)retryBlock ports:(NSArray *)ports
{
    methodNotSupported();
    return nil;
}

- (instancetype)initWithMapBlock:(id)mapBlock ports:(NSArray *)ports
{
    methodNotSupported();
    return nil;
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
    self = [super initWithMapBlock:mapBlock ports:@[@keypath(self.input)]];
    [self DF_setType:[NSArray class] forPort:@keypath(self.input)];
    [self DF_setType:[EXTNil null] forPort:@keypath(self.DF_output)];
    return self;
}

- (ReactiveConnection *)DF_newReactiveConnection
{
    return [SplitConnectionInfo new];
}

@end
