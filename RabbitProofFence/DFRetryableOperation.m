//
//  DFRetryableOperation.m
//  vf-hollywood
//
//  Created by Sinha, Gyanendra on 6/23/14.
//  Copyright (c) 2014 Conde Nast. All rights reserved.
//

#import "DFRetryableOperation.h"
#import "DFBackgroundOperation.h"
#import "ErrorRetryPolicy.h"
#import "DFMetaOperation_SubclassingHooks.h"

@interface DFRetryableOperation ()

@property (strong, nonatomic) NSMutableArray *errorRetryPolicies;

@end

@implementation DFRetryableOperation

+ (instancetype)operationFromBlock:(id)block ports:(NSArray *)ports
{
    DFOperation *operation = [DFBackgroundOperation operationFromBlock:block ports:ports];
    return [[[self class] alloc] initWithOperation:operation];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _errorRetryPolicies = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)addErrorRetryPolicy:(ErrorRetryPolicy *)retryPolicy
{
    if (!retryPolicy) {
        return;
    }
    dispatch_block_t block = ^(void) {
        [self.errorRetryPolicies addObject:retryPolicy];
    };
    [self safelyExecuteBlock:block];
}

- (void)addErrorRetryPolicies:(NSArray *)retryPolicies
{
    if ([retryPolicies count] > 0) {
        dispatch_block_t block = ^(void) {
            [self.errorRetryPolicies addObjectsFromArray:retryPolicies];
        };
        [self safelyExecuteBlock:block];
    }
}

- (void)removeErrorRetryPolicy:(ErrorRetryPolicy *)retryPolicy
{
    if (retryPolicy) {
        dispatch_block_t block = ^(void) {
            [self.errorRetryPolicies removeObject:retryPolicy];
        };
        [self safelyExecuteBlock:block];
    }
}

- (void)removeErrorRetryPolicies:(NSArray *)retryPolicies
{
    if ([retryPolicies count] > 0) {
        dispatch_block_t block = ^(void) {
            [self.errorRetryPolicies removeObjectsInArray:retryPolicies];
        };
        [self safelyExecuteBlock:block];
    }
}

- (ErrorRetryPolicy *)retryPolicyForError:(NSError *)error
{
    if (!error) {
        return nil;
    }
    __block ErrorRetryPolicy *foundPolicy = nil;
    dispatch_block_t block = ^(void) {
        NSUInteger index = [self.errorRetryPolicies indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
            ErrorRetryPolicy *retryPolicy = obj;
            if (retryPolicy.errorRegistrationBlock) {
                if (retryPolicy.errorRegistrationBlock(error)) {
                    *stop = YES;
                    return YES;
                }
            }
            return NO;
        }];
        if (index != NSNotFound) {
            foundPolicy = [self.errorRetryPolicies objectAtIndex:index];
        }
    };
    [self safelyExecuteBlock:block];
    return foundPolicy;
}

- (instancetype)clone:(NSMutableDictionary *)objToPointerMapping
{
    __block DFRetryableOperation *newRetryableOperation = nil;
    dispatch_block_t block = ^() {
        newRetryableOperation = [super clone:objToPointerMapping];
        newRetryableOperation.errorRetryPolicies = [[NSMutableArray alloc] initWithArray:self.errorRetryPolicies copyItems:YES];
    };
    [self safelyExecuteBlock:block];
    return newRetryableOperation;
}

- (instancetype)copyWithZone:(NSZone *)zone
{
    __block DFRetryableOperation *newRetryableOperation = nil;
    dispatch_block_t block = ^() {
        newRetryableOperation = [super copyWithZone:zone];
        newRetryableOperation.errorRetryPolicies = [[NSMutableArray alloc] initWithArray:self.errorRetryPolicies copyItems:YES];
    };
    [self safelyExecuteBlock:block];
    return newRetryableOperation;
}

- (BOOL)willRetryOperationForError:(NSError *)error
{
    //if retry policy exists for error and it can retry
    ErrorRetryPolicy *retryPolicy = [self retryPolicyForError:error];
    if (![retryPolicy shouldRetry]) {
        return NO;
    }
    NSTimeInterval waitInterval = retryPolicy.waitInterval;
    DFOperation *newOperation = [self.executingOperation clone];
    [retryPolicy retried];
    if (waitInterval == 0) {
        [self startOperation:newOperation];
    }
    else {
        self.executingOperation = nil;
        //retry after wait interval
        NSLog(@"%@ Error Retrying after %f, cause : %@",self, waitInterval, error);
        @weakify(self);
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, waitInterval * NSEC_PER_SEC);
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_after(popTime, queue, ^{
            @strongify(self);
            if (!self) {
                return;
            }
            dispatch_block_t block = ^(void) {
                if (self.state == OperationStateDone) {
                    return;
                }
                else {
                    [self startOperation:newOperation];
                }
            };
            [self safelyExecuteBlock:block];
        });
    }
    return YES;
}

- (void)operation:(DFOperation *)operation stateChanged:(id)changedValue
{
    dispatch_block_t block = ^() {
        if ((self.state == OperationStateDone) || (operation.state != OperationStateDone)) {
            return;
        }
        [operation safelyRemoveObserverWithBlockToken:self.operationObservationToken];
        self.operationObservationToken = nil;
        self.executingOperation = nil;
        if (![self willRetryOperationForError:operation.error]) {
            self.error = operation.error;
            self.output = [self processOutput:operation.output];
            [self done];
        }
    };
    [self safelyExecuteBlock:block];
}

@end
