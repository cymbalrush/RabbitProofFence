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
        self.inputPorts = @[@keypath(self.input)];
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
        self.executionObj = [[self class] executionObjFromBlock:wrappingBlock];
        self.executionObj.executionBlock = wrappingBlock;
    }
    return self;
}

- (BOOL)execute
{
    Execution_Class *executionObj = self.executionObj;
    BOOL result = NO;
    if (executionObj.executionBlock) {
        @try {
            [self prepareExecutionObj:executionObj];
            id wrappedValue = [executionObj execute];
            if ([wrappedValue boolValue]) {
                self.executionCount ++;
                self.output = [executionObj valueForArgAtIndex:0];
                result = YES;
            }
        }
        @catch (NSException *exception) {
            self.error = NSErrorFromException(exception);
        }
        @finally {
            [self breakRefCycleForExecutionObj:executionObj];
        }
    }
    return result;
}

@end
