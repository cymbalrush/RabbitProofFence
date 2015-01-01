//
//  DFLoopOperation.m
//  vf-hollywood
//
//  Created by Sinha, Gyanendra on 6/23/14.
//  Copyright (c) 2014 Conde Nast. All rights reserved.
//

#import "DFLoopOperation.h"
#import "BlockDescription.h"
#import "DFMetaOperation_SubclassingHooks.h"

@interface DFLoopOperation ()

@property (strong, nonatomic) NSPredicate *predicate;

@property (assign, nonatomic) NSUInteger executionCount;

@end

@implementation DFLoopOperation

+ (instancetype)operationFromBlock:(id)block ports:(NSArray *)ports
{
    return [[[self class] alloc] initWithRetryBlock:block ports:ports];
}

- (instancetype)initWithOperation:(DFOperation *)operation predicate:(NSPredicate *)predicate
{
    self = [super initWithOperation:operation];
    if (self) {
        self.predicate = predicate;
    }
    return self;
}

- (instancetype)initWithOperation:(DFOperation *)operation
{
    self = [super initWithOperation:operation];
    if (self) {
        self.predicate = [NSPredicate predicateWithValue:YES];
    }
    return self;
}

- (instancetype)initWithRetryBlock:(id)retryBlock ports:(NSArray *)ports
{
    self = [self init];
    if (self) {
        Execution_Class *executionObj = [[self class] executionObjFromBlock:retryBlock];
        NSUInteger n = [executionObj numberOfPorts];
        if ((n > 0) && !([ports count] == n && [[NSSet setWithArray:ports] count] == [ports count])) {
            //throw an exception
            NSString *reason = [NSString stringWithFormat:@"Duplicate property names, make sure that property names are unique"];
            @throw [NSException exceptionWithName:DFOperationExceptionDuplicatePropertyNames reason:reason userInfo:nil];
        }
        //this will hold values
        self.inputPorts = ports;
        self.executionObj = executionObj;
        self.executionObj.executionBlock = retryBlock;
    }
    return self;
}

- (void)setRetryBlock:(id)retryBlock
{
    dispatch_block_t block = ^(void) {
        self.executionObj.executionBlock = retryBlock;
    };
    [self safelyExecuteBlock:block];
}

- (instancetype)clone:(NSMutableDictionary *)objToPointerMapping
{
    __block DFLoopOperation *newLoopOperation = nil;
    dispatch_block_t block = ^() {
        newLoopOperation = [super clone:objToPointerMapping];
        newLoopOperation.predicate = self.predicate;
    };
    [self safelyExecuteBlock:block];
    return newLoopOperation;
}

- (instancetype)copyWithZone:(NSZone *)zone
{
    __block DFLoopOperation *newLoopOperation = nil;
    dispatch_block_t block = ^() {
        newLoopOperation = [super copyWithZone:zone];
        newLoopOperation.predicate = self.predicate;
    };
    [self safelyExecuteBlock:block];
    return newLoopOperation;
}

- (void)prepareOperation:(DFOperation *)operation
{
    if (self.retryBlock) {
        return;
    }
    [super prepareOperation:operation];
}

- (id)retryBlock
{
    return self.executionObj.executionBlock;
}

- (BOOL)execute
{
    if (self.retryBlock) {
        Execution_Class *executionObj = self.executionObj;
        [self prepareExecutionObj:executionObj];
        DFOperation *operation = nil;
        @try {
            operation = [executionObj execute];
        }
        @catch (NSException *ex) {
            self.error = NSErrorFromException(ex);
        }
        @finally {
            [self breakRefCycleForExecutionObj:executionObj];
        }
        if (operation) {
            [self startOperation:operation];
            self.executionCount ++;
            return YES;
        }
    }
    else if (self.operation) {
        if ([self.predicate evaluateWithObject:self]) {
            DFOperation *newOperation = [self.operation clone];
            [self startOperation:newOperation];
            self.executionCount ++;
            return YES;
        }
    }
    return NO;
}

- (void)operation:(DFOperation *)operation stateChanged:(id)changedValue
{
    dispatch_block_t block = ^(void) {
        if ((self.state == OperationStateDone) || (operation.state != OperationStateDone)) {
            return;
        }
        self.error = operation.error;
        self.output = operation.output;
        self.executingOperationInfo = nil;
        //if it's suspended then don't retry
        if (![self execute]) {
            [self done];
        }
    };
    [self safelyExecuteBlock:block];
}

- (void)main
{
    dispatch_block_t block = ^(void) {
        if (self.state != OperationStateExecuting) {
            return;
        }
        if (!self.error) {
            if ([self execute]) {
                return;
            }
        }
        [self done];
    };
    [self safelyExecuteBlock:block];
}

@end
