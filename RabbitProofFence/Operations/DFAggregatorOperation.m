//
//  DFAggregatorOperation.m

//
//  Created by Sinha, Gyanendra on 6/23/14.

//

#import "DFAggregatorOperation.h"
#import "DFReactiveOperation_SubclassingHooks.h"
#import "EXTNil.h"

@interface DFAggregatorOperation ()

@property (strong, nonatomic) NSMutableArray *DF_accumulator;

@end

@implementation DFAggregatorOperation

@dynamic input;

+ (instancetype)operationFromBlock:(id)block ports:(NSArray *)ports
{
    methodNotSupported();
    return nil;
}

+ (instancetype)aggregator
{
    return [self new];
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
        self.DF_accumulator = [NSMutableArray array];
        NSArray *(^block)(id input, DFAggregatorOperation *selfRef) = ^(id input, DFAggregatorOperation *selfRef) {
            input = input ? input : [EXTNil null];
            [selfRef.DF_accumulator addObject:input];
            return selfRef.DF_accumulator;
        };
        NSArray *ports = @[@keypath(self.input), @keypath(self.selfRef)];
        self.DF_inputPorts = ports;
        self.DF_executionObj = [[self class] DF_executionObjFromBlock:block];
        self.DF_executionObj.executionBlock = block;
        [self DF_populateTypesFromBlock:block ports:ports];
        [self DF_setType:[NSArray class] forPort:@keypath(self.DF_output)];
    }
    return self;
}

- (BOOL)DF_execute
{
    Execution_Class *executionObj = self.DF_executionObj;
    NSError *error = error;
    @try {
        [self DF_prepareExecutionObj:executionObj];
        [executionObj execute];
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
    else {
        return YES;
    }
}

- (void)DF_done
{
    if (!self.DF_error && self.DF_accumulator.count > 0) {
        self.DF_output = self.DF_accumulator;
    }
    [super DF_done];
}

@end
