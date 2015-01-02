//
//  DFAggregatorOperation.m
//  vf-hollywood
//
//  Created by Sinha, Gyanendra on 6/23/14.
//  Copyright (c) 2014 Conde Nast. All rights reserved.
//

#import "DFAggregatorOperation.h"
#import "DFReactiveOperation_SubclassingHooks.h"
#import "EXTNil.h"

@interface DFAggregatorOperation ()

@property (strong, nonatomic) NSMutableArray *accumulator;

@end

@implementation DFAggregatorOperation

@dynamic input;

+ (instancetype)operationFromBlock:(id)block ports:(NSArray *)ports
{
    methodNotSupported();
    return nil;
}

+ (instancetype)aggregator
{
    return [self new];
}

- (instancetype)initWithOperation:(DFOperation *)operation
{
    methodNotSupported();
    return nil;
}

- (instancetype)initWithOperation:(DFOperation *)operation predicate:(NSPredicate *)predicate
{
    methodNotSupported();
    return nil;
}

- (instancetype)initWithRetryBlock:(id)retryBlock ports:(NSArray *)ports
{
    methodNotSupported();
    return nil;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.accumulator = [NSMutableArray array];
        NSArray *(^block)(id input, DFAggregatorOperation *selfRef) = ^(id input, DFAggregatorOperation *selfRef) {
            input = input ? input : [EXTNil null];
            [selfRef.accumulator addObject:input];
            return selfRef.accumulator;
        };
        self.executionObj = [[self class] executionObjFromBlock:block];
        self.executionObj.executionBlock = block;
        self.inputPorts = @[@keypath(self.input), @keypath(self.selfRef)];
    }
    return self;
}

- (void)connectWithOperation:(DFOperation *)operation
{
    [super addReactiveDependency:operation withBindings:@{@keypath(self.input) : @keypath(operation.output)}];
}

- (BOOL)execute
{
    Execution_Class *executionObj = self.executionObj;
    if (executionObj.executionBlock) {
        @try {
            [self prepareExecutionObj:executionObj];
            [executionObj execute];
        }
        @catch (NSException *exception) {
            self.error = NSErrorFromException(exception);
        }
        @finally {
            [self breakRefCycleForExecutionObj:executionObj];
        }
        if (!self.error) {
            return YES;
        }
    }
    return NO;
}

- (void)done
{
    if (self.accumulator.count > 0 && !self.error) {
        self.output = self.accumulator;
    }
    [super done];
}

@end
