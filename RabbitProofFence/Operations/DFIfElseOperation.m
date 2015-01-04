//
//  DFIfElseOperation.m
//  vf-hollywood
//
//  Created by Sinha, Gyanendra on 6/23/14.
//  Copyright (c) 2014 Conde Nast. All rights reserved.
//

#import "DFIfElseOperation.h"
#import "DFMetaOperation_SubclassingHooks.h"

@interface DFIfElseOperation ()

@property (strong, nonatomic) DFOperation *DF_ifOperation;

@property (strong, nonatomic) DFOperation *DF_elseOperation;

@property (strong, nonatomic) NSPredicate *DF_predicate;

@end

@implementation DFIfElseOperation

+ (DFIfElseOperation *)ifElseOperationFromIfOperation:(DFOperation *)ifOperation
                                      elseOperation:(DFOperation *)elseOperation
                                          predicate:(NSPredicate *)predicate
{
    return [[[self class] alloc] initWithIfOperation:ifOperation elseOperation:elseOperation predicate:predicate];
}

- (instancetype)initWithIfOperation:(DFOperation *)ifOperation
                      elseOperation:(DFOperation *)elseOperation
                          predicate:(NSPredicate *)predicate
{
    if (![ifOperation.freePorts isEqualToArray:elseOperation.freePorts]) {
        NSString *reason = [NSString stringWithFormat:@"Inequal free ports"];
        @throw [NSException exceptionWithName:DFOperationExceptionInEqualInputPorts reason:reason userInfo:nil];
    }
    self = [super init];
    if (self) {
        self.DF_ifOperation = ifOperation;
        self.DF_elseOperation = elseOperation;
        self.DF_predicate = predicate;
        self.DF_inputPorts = [[ifOperation freePorts] copy];
        self.DF_executionObj = [Execution_Class instanceForNumberOfArguments:[self.DF_inputPorts count]];
    }
    return self;
}

- (instancetype)DF_clone:(NSMutableDictionary *)objToPointerMapping
{
    __block DFIfElseOperation *newIfElseOperation = nil;
    dispatch_block_t block = ^(void) {
        newIfElseOperation = [super DF_clone:objToPointerMapping];
        newIfElseOperation.DF_ifOperation = [self.DF_ifOperation DF_clone:objToPointerMapping];
        newIfElseOperation.DF_elseOperation = [self.DF_elseOperation DF_clone:objToPointerMapping];
        newIfElseOperation.DF_predicate = [self.DF_predicate copy];
    };
    [self DF_safelyExecuteBlock:block];
    return newIfElseOperation;
}

- (id)copyWithZone:(NSZone *)zone
{
    __block DFIfElseOperation *newIfElseOperation = nil;
    dispatch_block_t block = ^() {
        newIfElseOperation = [super copyWithZone:zone];
        newIfElseOperation.DF_ifOperation = [self.DF_ifOperation copyWithZone:zone];
        newIfElseOperation.DF_elseOperation = [self.DF_elseOperation copyWithZone:zone];
        newIfElseOperation.DF_predicate = [self.DF_predicate copy];
    };
    [self DF_safelyExecuteBlock:block];
    return newIfElseOperation;
}

- (DFOperation *)ifOperation
{
    return self.DF_ifOperation;
}

- (DFOperation *)elseOperation
{
    return self.DF_elseOperation;
}

- (NSPredicate *)predicate
{
    return self.DF_predicate;
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
        else if (self.DF_predicate) {
            BOOL result = [self.DF_predicate evaluateWithObject:self];
            if (result && self.DF_ifOperation) {
                [self DF_startOperation:self.DF_ifOperation];
                return;
            }
            else if (!result && self.DF_elseOperation) {
                [self DF_startOperation:self.DF_elseOperation];
                return;
            }
        }
        [self DF_done];
    };
    [self DF_safelyExecuteBlock:block];
}

@end
