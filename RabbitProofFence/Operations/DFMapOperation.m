//
//  DFMapOperation.m
//  vf-hollywood
//
//  Created by Sinha, Gyanendra on 6/23/14.
//  Copyright (c) 2014 Conde Nast. All rights reserved.
//

#import "DFMapOperation.h"
#import "DFReactiveOperation_SubclassingHooks.h"

@implementation DFMapOperation

+ (instancetype)operationFromBlock:(id)block ports:(NSArray *)ports
{
    return [[[self class] alloc] initWithMapBlock:block ports:ports];
}

- (instancetype)initWithMapBlock:(id)mapBlock ports:(NSArray *)ports
{
    self = [super init];
    if (self) {
        self.executionObj = [[self class] executionObjFromBlock:mapBlock];
        self.executionObj.executionBlock = mapBlock;
        self.inputPorts = ports;
    }
    return self;
}

- (BOOL)execute
{
    Execution_Class *executionObj = self.executionObj;
    if (executionObj.executionBlock) {
        [self prepareExecutionObj:executionObj];
        @try {
            self.output = [executionObj execute];
        }
        @catch (NSException *exception) {
            self.error = NSErrorFromException(exception);
        }
        @finally {
            [self breakRefCycleForExecutionObj:self.executionObj];
        }
        if (!self.error) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)next
{
    BOOL result = YES;
    while ([self canExecute]) {
        result = [super next];
        if (!result) {
            break;
        }
    }
    if ([self isDone]) {
        result = NO;
    }
    return result;
}

@end
