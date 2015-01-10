//
//  DFTryCatchOperation.m
//  vf-hollywood
//
//  Created by Sinha, Gyanendra on 6/23/14.
//  Copyright (c) 2014 Conde Nast. All rights reserved.
//

#import "DFTryCatchOperation.h"
#import "DFMetaOperation_SubclassingHooks.h"

@interface DFTryCatchOperation ()

@property (strong, nonatomic) DFOperation *DF_tryOperation;

@property (strong, nonatomic) DFOperation *DF_catchOperation;

@property (copy, nonatomic) BOOL(^DF_errorBlock)(NSError *error, DFTryCatchOperation *operation);

@end

@implementation DFTryCatchOperation

- (instancetype)initWithTryOperation:(DFOperation *)tryOperation
                   andCatchOperation:(DFOperation *)catchOperation
                       andErrorBlock:(BOOL(^)(NSError *error, DFTryCatchOperation *operation))errorBlock
{
    if (![tryOperation.freePorts isEqualToArray:catchOperation.freePorts]) {
        NSString *reason = [NSString stringWithFormat:@"Free Ports Not Equal"];
        @throw [NSException exceptionWithName:DFOperationExceptionInEqualPorts reason:reason userInfo:nil];
    }
    if (![tryOperation.freePortTypes isEqualToDictionary:catchOperation.freePortTypes]) {
        NSString *reason = [NSString stringWithFormat:@"Free Port Types Not Equal"];
        @throw [NSException exceptionWithName:DFOperationExceptionInEqualPorts reason:reason userInfo:nil];
    }
    
    self = [super init];
    if (self) {
        self.DF_tryOperation = tryOperation;
        self.DF_catchOperation = catchOperation;
        self.DF_operation = tryOperation;
        self.DF_errorBlock = errorBlock;
        self.DF_inputPorts = [[tryOperation freePorts] copy];
        self.DF_executionObj = [Execution_Class instanceForNumberOfArguments:self.DF_inputPorts.count];
        [self DF_addPortTypes:tryOperation.freePortTypes];
    }
    return self;
}

- (instancetype)DF_clone:(NSMutableDictionary *)objToPointerMapping
{
    __block DFTryCatchOperation *newTryCatchPOperation = nil;
    dispatch_block_t block = ^(void) {
        newTryCatchPOperation = [super DF_clone:objToPointerMapping];
        newTryCatchPOperation.DF_tryOperation = [self.DF_tryOperation DF_clone:objToPointerMapping];
        newTryCatchPOperation.DF_catchOperation = [self.DF_catchOperation DF_clone:objToPointerMapping];
        newTryCatchPOperation.DF_errorBlock = self.DF_errorBlock;
    };
    [self DF_safelyExecuteBlock:block];
    return newTryCatchPOperation;
}

- (id)copyWithZone:(NSZone *)zone
{
    __block DFTryCatchOperation *newTryCatchPOperation = nil;
    dispatch_block_t block = ^(void) {
        newTryCatchPOperation = [super copyWithZone:zone];
        newTryCatchPOperation.DF_tryOperation = [self.DF_tryOperation copyWithZone:zone];
        newTryCatchPOperation.DF_catchOperation = [self.DF_catchOperation copyWithZone:zone];
        newTryCatchPOperation.DF_errorBlock = self.DF_errorBlock;
    };
    [self DF_safelyExecuteBlock:block];
    return newTryCatchPOperation;
}

- (DFOperation *)tryOperation
{
    return self.DF_tryOperation;
}

- (DFOperation *)catchOperation
{
    return self.DF_catchOperation;
}

- (void)DF_operation:(DFOperation *)operation stateChanged:(id)changedValue
{
    dispatch_block_t block = ^() {
        //return if either operation is done or observed operation is not done
        OperationState state = [changedValue integerValue];
        if ((self.DF_state == OperationStateDone) || (state != OperationStateDone)) {
            return;
        }
        self.DF_runningOperationInfo = nil;
        if (operation == self.DF_tryOperation) {
            if (self.DF_catchOperation &&
                self.DF_errorBlock &&
                self.DF_errorBlock(operation.DF_error, self)) {
                [self DF_startOperation:self.DF_catchOperation];
                return;
            }
        }
        NSError *error = operation.DF_error;
        if (error) {
            self.DF_error = error;
            self.DF_output = errorObject(error);
        }
        else {
            self.DF_output = operation.DF_output;
        }
        [self DF_done];
    };
    [self DF_safelyExecuteBlock:block];
}

- (void)main
{
    dispatch_block_t block = ^(void) {
        if (self.DF_state != OperationStateExecuting) {
            return;
        }
        NSError *error = [self DF_incomingPortErrors];
        if (error) {
            self.DF_error = error;
            self.DF_output = errorObject(error);
        }
        if (error) {
            self.DF_error = error;
            self.DF_output = errorObject(error);
        }
        else {
            if (self.DF_tryOperation) {
                [self DF_startOperation:self.DF_tryOperation];
                return;
            }
        }
        [self DF_done];
    };
    [self DF_safelyExecuteBlock:block];
}

@end
