//
//  DFReduceOperation.m

//
//  Created by Sinha, Gyanendra on 6/23/14.

//

#import "DFReduceOperation.h"
#import "DFReactiveOperation_SubclassingHooks.h"

@interface DFReduceOperation ()

@property (strong, nonatomic) id DF_acc;

@end

@implementation DFReduceOperation

+ (instancetype)operationFromBlock:(id)block ports:(NSArray *)ports
{
    return [[[self class] alloc] initWithReduceBlock:block ports:ports];
}

- (instancetype)initWithReduceBlock:(id)reduceBlock ports:(NSArray *)ports
{
    self = [super init];
    if (self) {
        self.DF_executionObj = [[self class] DF_executionObjFromBlock:reduceBlock];
        self.DF_executionObj.executionBlock = reduceBlock;
        if ([ports containsObject:@keypath(self.seed)]) {
            ports = [ports arrayByAddingObject:@keypath(self.seed)];
        }
        self.DF_inputPorts = ports;
    }
    return self;
}

- (BOOL)DF_execute
{
    NSError *error = nil;
    Execution_Class *executionObj = self.DF_executionObj;
    @try {
        [self DF_prepareExecutionObj:executionObj];
        self.DF_acc = [executionObj execute];
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
    return YES;
}

- (void)DF_done
{
    if (!self.DF_error) {
        self.DF_output = self.acc;
    }
    [super DF_done];
}

- (void)main
{
    dispatch_block_t block = ^(void) {
        if (self.DF_state != OperationStateExecuting) {
            return;
        }
        self.DF_acc = self.seed;
        [super main];
    };
    [self DF_safelyExecuteBlock:block];
}


@end
