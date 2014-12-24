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

@property (strong, nonatomic) DFOperation *ifOperation;

@property (strong, nonatomic) DFOperation *elseOperation;

@property (strong, nonatomic) NSPredicate *predicate;

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
        self.ifOperation = ifOperation;
        self.elseOperation = elseOperation;
        self.predicate = predicate;
        self.inputPorts = [[ifOperation freePorts] copy];
        self.executionObj = [Execution_Class instanceForNumberOfArguments:[self.inputPorts count]];
    }
    return self;
}

- (instancetype)clone:(NSMutableDictionary *)objToPointerMapping
{
    __block DFIfElseOperation *newIfElseOperation = nil;
    dispatch_block_t block = ^(void) {
        newIfElseOperation = [super clone:objToPointerMapping];
        newIfElseOperation.ifOperation = [self.ifOperation clone:objToPointerMapping];
        newIfElseOperation.elseOperation = [self.elseOperation clone:objToPointerMapping];
        newIfElseOperation.predicate = [self.predicate copy];
    };
    [self safelyExecuteBlock:block];
    return newIfElseOperation;
}

- (id)copyWithZone:(NSZone *)zone
{
    __block DFIfElseOperation *newIfElseOperation = nil;
    dispatch_block_t block = ^() {
        newIfElseOperation = [super copyWithZone:zone];
        newIfElseOperation.ifOperation = [self.ifOperation copyWithZone:zone];
        newIfElseOperation.elseOperation = [self.elseOperation copyWithZone:zone];
        newIfElseOperation.predicate = [self.predicate copy];
    };
    [self safelyExecuteBlock:block];
    return newIfElseOperation;
}

- (void)main
{
    dispatch_block_t block = ^(void) {
        if (self.state != OperationStateExecuting) {
            return;
        }
        if (!self.error) {
            if ([self.predicate evaluateWithObject:self]) {
                [self startOperation:self.ifOperation];
            }
            else {
                [self startOperation:self.elseOperation];
            }
        }
        else {
            self.output = [self processOutput:nil];
            [self done];
        }
    };
    [self safelyExecuteBlock:block];
}

@end
