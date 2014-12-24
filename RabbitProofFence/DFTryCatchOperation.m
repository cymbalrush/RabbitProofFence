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

@property (strong, nonatomic) DFOperation *tryOperation;

@property (strong, nonatomic) DFOperation *catchOperation;

@property (copy, nonatomic) BOOL(^errorBlock)(NSError *error);

@end

@implementation DFTryCatchOperation

- (instancetype)initWithTryOperation:(DFOperation *)tryOperation
                   andCatchOperation:(DFOperation *)catchOperation
                       andErrorBlock:(BOOL(^)(NSError *error))errorBlock
{
    if (![tryOperation.freePorts isEqualToArray:catchOperation.freePorts]) {
        [catchOperation freePorts];
        NSString *reason = [NSString stringWithFormat:@"Inequal free ports"];
        @throw [NSException exceptionWithName:DFOperationExceptionInEqualInputPorts reason:reason userInfo:nil];
    }
    
    self = [super init];
    if (self) {
        self.tryOperation = tryOperation;
        self.catchOperation = catchOperation;
        self.operation = tryOperation;
        self.errorBlock = errorBlock;
        self.inputPorts = [[tryOperation freePorts] copy];
        self.executionObj = [Execution_Class instanceForNumberOfArguments:[self.inputPorts count]];
    }
    return self;
}

- (instancetype)clone:(NSMutableDictionary *)objToPointerMapping
{
    __block DFTryCatchOperation *newTryCatchPOperation = nil;
    dispatch_block_t block = ^(void) {
        newTryCatchPOperation = [super clone:objToPointerMapping];
        newTryCatchPOperation.tryOperation = [self.tryOperation clone:objToPointerMapping];
        newTryCatchPOperation.catchOperation = [self.catchOperation clone:objToPointerMapping];
        newTryCatchPOperation.errorBlock = self.errorBlock;
    };
    [self safelyExecuteBlock:block];
    return newTryCatchPOperation;
}

- (id)copyWithZone:(NSZone *)zone
{
    __block DFTryCatchOperation *newTryCatchPOperation = nil;
    dispatch_block_t block = ^(void) {
        newTryCatchPOperation = [super copyWithZone:zone];
        newTryCatchPOperation.tryOperation = [self.tryOperation copyWithZone:zone];
        newTryCatchPOperation.catchOperation = [self.catchOperation copyWithZone:zone];
        newTryCatchPOperation.errorBlock = self.errorBlock;
    };
    [self safelyExecuteBlock:block];
    return newTryCatchPOperation;

}

- (void)operation:(DFOperation *)operation stateChanged:(id)changedValue
{
    dispatch_block_t block = ^() {
        //return if either operation is done or observed operation is not done
        if ((self.state == OperationStateDone) || (operation.state != OperationStateDone)) {
            return;
        }
        [operation safelyRemoveObserverWithBlockToken:self.operationObservationToken];
        self.operationObservationToken = nil;
        self.executingOperation = nil;
        if (operation == self.tryOperation) {
            if (self.errorBlock && self.errorBlock(operation.error)) {
                [self startOperation:self.catchOperation];
                return;
            }
        }
        self.error = operation.error;
        self.output = [self processOutput:operation.output];
        [self done];
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
            if (self.tryOperation) {
                [self startOperation:self.tryOperation];
                return;
            }
        }
        self.output = [self processOutput:nil];
        [self done];
    };
    [self safelyExecuteBlock:block];
}

@end
