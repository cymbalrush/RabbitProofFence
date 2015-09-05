//
//  DFRetryableOperation.m

//
//  Created by Sinha, Gyanendra on 6/23/14.

//

#import "DFRetryableOperation.h"
#import "DFBackgroundOperation.h"
#import "ErrorRetryPolicy.h"
#import "DFMetaOperation_SubclassingHooks.h"

@interface DFRetryableOperation ()

@property (strong, nonatomic) NSMutableArray *DF_errorRetryPolicies;

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
        _DF_errorRetryPolicies = [NSMutableArray new];
    }
    return self;
}

- (void)addErrorRetryPolicy:(ErrorRetryPolicy *)retryPolicy
{
    if (!retryPolicy) {
        return;
    }
    dispatch_block_t block = ^(void) {
        [self.DF_errorRetryPolicies addObject:retryPolicy];
    };
    [self DF_safelyExecuteBlock:block];
}

- (void)addErrorRetryPolicies:(NSArray *)retryPolicies
{
    if ([retryPolicies count] > 0) {
        dispatch_block_t block = ^(void) {
            [self.DF_errorRetryPolicies addObjectsFromArray:retryPolicies];
        };
        [self DF_safelyExecuteBlock:block];
    }
}

- (void)removeErrorRetryPolicy:(ErrorRetryPolicy *)retryPolicy
{
    if (retryPolicy) {
        dispatch_block_t block = ^(void) {
            [self.DF_errorRetryPolicies removeObject:retryPolicy];
        };
        [self DF_safelyExecuteBlock:block];
    }
}

- (void)removeErrorRetryPolicies:(NSArray *)retryPolicies
{
    if ([retryPolicies count] > 0) {
        dispatch_block_t block = ^(void) {
            [self.DF_errorRetryPolicies removeObjectsInArray:retryPolicies];
        };
        [self DF_safelyExecuteBlock:block];
    }
}

- (ErrorRetryPolicy *)retryPolicyForError:(NSError *)error
{
    if (!error) {
        return nil;
    }
    __block ErrorRetryPolicy *foundPolicy = nil;
    dispatch_block_t block = ^(void) {
        NSUInteger index = [self.DF_errorRetryPolicies indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
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
            foundPolicy = [self.DF_errorRetryPolicies objectAtIndex:index];
        }
    };
    [self DF_safelyExecuteBlock:block];
    return foundPolicy;
}

- (instancetype)DF_clone:(NSMutableDictionary *)objToPointerMapping
{
    __block DFRetryableOperation *newRetryableOperation = nil;
    dispatch_block_t block = ^() {
        newRetryableOperation = [super DF_clone:objToPointerMapping];
        newRetryableOperation.DF_errorRetryPolicies = [[NSMutableArray alloc] initWithArray:self.DF_errorRetryPolicies
                                                                                  copyItems:YES];
    };
    [self DF_safelyExecuteBlock:block];
    return newRetryableOperation;
}

- (instancetype)copyWithZone:(NSZone *)zone
{
    __block DFRetryableOperation *newRetryableOperation = nil;
    dispatch_block_t block = ^() {
        newRetryableOperation = [super copyWithZone:zone];
        newRetryableOperation.DF_errorRetryPolicies = [[NSMutableArray alloc] initWithArray:self.DF_errorRetryPolicies
                                                                                  copyItems:YES];
    };
    [self DF_safelyExecuteBlock:block];
    return newRetryableOperation;
}

- (BOOL)DF_willRetryOperationForError:(NSError *)error
{
    //if retry policy exists for error and it can retry
    ErrorRetryPolicy *retryPolicy = [self retryPolicyForError:error];
    if (![retryPolicy shouldRetry]) {
        return NO;
    }
    NSTimeInterval waitInterval = retryPolicy.waitInterval;
    DFOperation *newOperation = [self.DF_operation DF_clone];
    [retryPolicy retried];
    if (waitInterval == 0) {
        [self DF_startOperation:newOperation];
    }
    else {
        self.DF_runningOperationInfo = nil;
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
                if (self.DF_state == OperationStateDone) {
                    return;
                }
                else {
                    [self DF_startOperation:newOperation];
                }
            };
            [self DF_safelyExecuteBlock:block];
        });
    }
    return YES;
}

- (void)DF_operation:(DFOperation *)operation stateChanged:(id)changedValue
{
    dispatch_block_t block = ^() {
        OperationState state = [changedValue integerValue];
        if ((self.DF_state == OperationStateDone) || (state != OperationStateDone)) {
            return;
        }
        self.DF_runningOperationInfo = nil;
        NSError *error = operation.DF_error;
        if (![self DF_willRetryOperationForError:error]) {
            if (error) {
                self.DF_error = error;
                self.DF_output = errorObject(error);
            }
            else {
                self.DF_output = operation.DF_output;
            }
            [self DF_done];
        }
    };
    [self DF_safelyExecuteBlock:block];
}

@end
