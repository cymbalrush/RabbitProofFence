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

@property (strong, nonatomic) NSPredicate *DF_predicate;

@property (assign, nonatomic) NSUInteger DF_executionCount;

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
        self.DF_predicate = predicate;
    }
    return self;
}

- (instancetype)initWithOperation:(DFOperation *)operation
{
    self = [super initWithOperation:operation];
    if (self) {
        self.DF_predicate = [NSPredicate predicateWithValue:YES];
    }
    return self;
}

- (instancetype)initWithRetryBlock:(id)retryBlock ports:(NSArray *)ports
{
    self = [self init];
    if (self) {
        Execution_Class *executionObj = [[self class] DF_executionObjFromBlock:retryBlock];
        NSUInteger n = [executionObj numberOfPorts];
        if ((n > 0) && !([ports count] == n && [[NSSet setWithArray:ports] count] == [ports count])) {
            //throw an exception
            NSString *reason = [NSString stringWithFormat:@"Duplicate property names, make sure that property names are unique"];
            @throw [NSException exceptionWithName:DFOperationExceptionDuplicatePropertyNames reason:reason userInfo:nil];
        }
        //this will hold values
        self.DF_inputPorts = ports;
        self.DF_executionObj = executionObj;
        self.DF_executionObj.executionBlock = retryBlock;
        [self DF_populateTypesFromBlock:retryBlock ports:ports];
    }
    return self;
}

- (instancetype)DF_clone:(NSMutableDictionary *)objToPointerMapping
{
    __block DFLoopOperation *newLoopOperation = nil;
    dispatch_block_t block = ^() {
        newLoopOperation = [super DF_clone:objToPointerMapping];
        newLoopOperation.DF_predicate = self.DF_predicate;
    };
    [self DF_safelyExecuteBlock:block];
    return newLoopOperation;
}

- (instancetype)copyWithZone:(NSZone *)zone
{
    __block DFLoopOperation *newLoopOperation = nil;
    dispatch_block_t block = ^() {
        newLoopOperation = [super copyWithZone:zone];
        newLoopOperation.DF_predicate = self.DF_predicate;
    };
    [self DF_safelyExecuteBlock:block];
    return newLoopOperation;
}

- (void)DF_prepareOperation:(DFOperation *)operation
{
    if (self.retryBlock) {
        return;
    }
    [super DF_prepareOperation:operation];
}

- (id)retryBlock
{
    return self.DF_executionObj.executionBlock;
}

- (void)setRetryBlock:(id)retryBlock
{
    dispatch_block_t block = ^(void) {
        self.DF_executionObj.executionBlock = retryBlock;
    };
    [self DF_safelyExecuteBlock:block];
}

- (NSPredicate *)predicate
{
    return self.DF_predicate;
}

- (BOOL)DF_execute
{
    DFOperation *operation = nil;
    if (self.retryBlock) {
        Execution_Class *executionObj = self.DF_executionObj;
        [self DF_prepareExecutionObj:executionObj];
        @try {
            operation = [executionObj execute];
        }
        @catch (NSException *ex) {
            NSError *error = NSErrorFromException(ex);
            self.DF_error = error;
            self.DF_output = errorObject(error);
        }
        @finally {
            [self DF_breakRefCycleForExecutionObj:executionObj];
        }
        
    }
    else if (self.DF_operation) {
        if ([self.DF_predicate evaluateWithObject:self]) {
            //clone
            operation = [self.DF_operation DF_clone];
        }
    }
    if (operation) {
        [self DF_startOperation:operation];
        return YES;
    }
    return NO;
}

- (void)DF_operation:(DFOperation *)operation stateChanged:(id)changedValue
{
    dispatch_block_t block = ^(void) {
        OperationState state = [changedValue integerValue];
        if ((self.DF_state == OperationStateDone) || (state != OperationStateDone)) {
            return;
        }
        self.DF_error = operation.DF_error;
        self.DF_output = operation.DF_output;
        self.DF_runningOperationInfo = nil;
        //if it's suspended then don't retry
        if (![self DF_next]) {
            [self DF_done];
        }
    };
    [self DF_safelyExecuteBlock:block];
}

- (BOOL)DF_next
{
    NSError *error = nil;
    if (!self.portErrorResolutionBlock) {
        error = [self DF_incomingPortErrors];
    }
    if (error) {
        self.DF_error = error;
        self.DF_output = errorObject(error);
        return NO;
    }
    BOOL result = [self DF_execute];
    if (result) {
        self.DF_executionCount ++;
    }
    return result;
}

- (void)main
{
    dispatch_block_t block = ^(void) {
        if (self.DF_state != OperationStateExecuting) {
            return;
        }
        NSError *error = nil;
        if (!self.portErrorResolutionBlock) {
            error = [self DF_incomingPortErrors];
        }
        if (error) {
            self.DF_error = error;
            self.DF_output = errorObject(error);
        }
        else {
            if ([self DF_next]) {
                return;
            }
        }
        [self DF_done];
    };
    [self DF_safelyExecuteBlock:block];
}

@end
