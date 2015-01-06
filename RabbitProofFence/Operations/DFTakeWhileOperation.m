//
//  DFTakeWhile.m
//  RabbitProofFence
//
//  Created by Sinha, Gyanendra on 12/31/14.
//  Copyright (c) 2014 Sinha, Gyanendra. All rights reserved.
//

#import "DFTakeWhileOperation.h"
#import "DFReactiveOperation_SubclassingHooks.h"

@implementation DFTakeWhileOperation

+ (instancetype)operationFromBlock:(id)block ports:(NSArray *)ports
{
    methodNotSupported();
    return nil;
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
        self.DF_inputPorts = @[@keypath(self.input)];
    }
    return self;
}

- (instancetype)initWithTakeWhileBlock:(BOOL (^)(id input))takeWhileBlock
{
    self = [self init];
    if (self) {
        //do a copy
        BOOL (^newTakeWhileBlock)(id input) = [takeWhileBlock copy];
        id (^wrappingBlock)(id input) = ^(id input) {
            return @(newTakeWhileBlock(input));
        };
        self.DF_executionObj = [[self class] DF_executionObjFromBlock:wrappingBlock];
        self.DF_executionObj.executionBlock = wrappingBlock;
    }
    return self;
}

- (Class)portType:(NSString *)port
{
    __block Class type = nil;
    dispatch_block_t block = ^(void) {
        type = [super portType:port];
        if ([port isEqualToString:@keypath(self.DF_output)] || [port isEqualToString:@keypath(self.output)]) {
            type = [super portType:@keypath(self.input)];
        }
    };
    [self DF_safelyExecuteBlock:block];
    return type;
}

- (BOOL)DF_execute
{
    NSError *error = nil;
    Execution_Class *executionObj = self.DF_executionObj;
    BOOL result = NO;
    @try {
        [self DF_prepareExecutionObj:executionObj];
        id wrappedValue = [executionObj execute];
        if ([wrappedValue boolValue]) {
            self.DF_output = [executionObj valueForArgAtIndex:0];
            result = YES;
        }
    }
    @catch (NSException *exception) {
        error = NSErrorFromException(exception);
    }
    @finally {
        [self DF_breakRefCycleForExecutionObj:executionObj];
    }
    if (error) {
        self.DF_error = error;
        self.DF_output = errorObject(error);
        return NO;
    }
    return result;
}

@end
