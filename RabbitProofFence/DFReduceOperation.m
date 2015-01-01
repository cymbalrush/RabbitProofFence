//
//  DFReduceOperation.m
//  vf-hollywood
//
//  Created by Sinha, Gyanendra on 6/23/14.
//  Copyright (c) 2014 Conde Nast. All rights reserved.
//

#import "DFReduceOperation.h"
#import "DFReactiveOperation_SubclassingHooks.h"

@implementation DFReduceOperation

+ (instancetype)operationFromBlock:(id)block ports:(NSArray *)ports
{
    return [[[self class] alloc] initWithReduceBlock:block ports:ports];
}

- (instancetype)initWithReduceBlock:(id)reduceBlock ports:(NSArray *)ports
{
    self = [super init];
    if (self) {
        self.executionObj = [[self class] executionObjFromBlock:reduceBlock];
        self.executionObj.executionBlock = reduceBlock;
        self.inputPorts = ports;
    }
    return self;
}

- (instancetype)clone:(NSMutableDictionary *)objToPointerMapping
{
    __block DFReduceOperation *newReduceOperation = nil;
    dispatch_block_t block = ^(void) {
        newReduceOperation = [super clone:objToPointerMapping];
        newReduceOperation.initialValue = self.initialValue;
    };
    [self safelyExecuteBlock:block];
    return newReduceOperation;
}

- (instancetype)copyWithZone:(NSZone *)zone
{
    __block DFReduceOperation *newReduceOperation = nil;
    dispatch_block_t block = ^(void) {
        newReduceOperation = [super copyWithZone:zone];
        newReduceOperation.initialValue = self.initialValue;
    };
    [self safelyExecuteBlock:block];
    return newReduceOperation;
}

- (void)setInitialValue:(id)initialValue
{
    dispatch_block_t block = ^(void) {
        _initialValue = initialValue;
        if (self.state == OperationStateReady) {
            self.accumulator = initialValue;
        }
    };
    [self safelyExecuteBlock:block];
}

- (BOOL)execute
{
    Execution_Class *executionObj = self.executionObj;
    if (executionObj.executionBlock) {
        @try {
            [self prepareExecutionObj:executionObj];
            self.accumulator = [executionObj execute];
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
    self.output = self.accumulator;
    [super done];
}

@end
