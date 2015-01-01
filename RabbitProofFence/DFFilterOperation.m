//
//  DFFilterOperation.m
//  vf-hollywood
//
//  Created by Sinha, Gyanendra on 6/23/14.
//  Copyright (c) 2014 Conde Nast. All rights reserved.
//

#import "DFFilterOperation.h"
#import "DFReactiveOperation_SubclassingHooks.h"
#import "DFVoidObject.h"

@implementation DFFilterOperation

@dynamic input;

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

- (instancetype)initWithFilterBlock:(BOOL (^)(id input))filterBlock
{
    self = [self init];
    if (self) {
        //do a copy
        BOOL (^newFilterBlock)(id input) = [filterBlock copy];
        id (^ wrappingBlock)(id input) = ^(id input) {
            return @(newFilterBlock(input));
        };
        self.executionObj = [[self class] executionObjFromBlock:wrappingBlock];
        self.executionObj.executionBlock = wrappingBlock;
    }
    return self;
}

- (BOOL)execute
{
    Execution_Class *executionObj = self.executionObj;
    if (executionObj.executionBlock) {
        @try {
            [self prepareExecutionObj:executionObj];
            id wrappedValue = [executionObj execute];
            if ([wrappedValue boolValue]) {
                self.executionCount ++;
                self.output = [executionObj valueForArgAtIndex:0];
            }
        }
        @catch (NSException *exception) {
            self.error = NSErrorFromException(exception);
        }
        @finally {
            [self breakRefCycleForExecutionObj:executionObj];
        }
        if (!self.error) {
            return YES;
        }
    }
    return NO;
}

@end
