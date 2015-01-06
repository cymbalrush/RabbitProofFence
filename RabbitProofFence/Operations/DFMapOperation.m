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
        self.DF_executionObj = [[self class] DF_executionObjFromBlock:mapBlock];
        self.DF_executionObj.executionBlock = mapBlock;
        self.DF_inputPorts = ports;
        [self DF_populateTypesFromBlock:mapBlock ports:ports];
    }
    return self;
}

- (BOOL)DF_execute
{
    NSError *error = nil;
    Execution_Class *executionObj = self.DF_executionObj;
    [self DF_prepareExecutionObj:executionObj];
    @try {
        self.DF_output = [executionObj execute];
    }
    @catch (NSException *exception) {
        error = NSErrorFromException(exception);
    }
    @finally {
        [self DF_breakRefCycleForExecutionObj:self.DF_executionObj];
    }
    if (error) {
        self.DF_error = error;
        self.DF_output = errorObject(error);
        return NO;
    }
    return YES;
}

- (BOOL)DF_next
{
    BOOL result = YES;
    while ([self DF_canExecute]) {
        result = [super DF_next];
        if (!result) {
            break;
        }
    }
    if ([self DF_isDone]) {
        result = NO;
    }
    return result;
}

@end
