//
//  DFLazyValueGenerator.m
//  vf-hollywood
//
//  Created by Sinha, Gyanendra on 6/23/14.
//  Copyright (c) 2014 Conde Nast. All rights reserved.
//

#import "DFGenerator.h"
#import "DFBackgroundOperation.h"
#import "DFMetaOperation_SubclassingHooks.h"
#import "DFVoidObject.h"

@interface DFEndValueGenerationException : NSException

@end

@implementation DFEndValueGenerationException

@end

@interface DFGenerator ()

@property (assign) BOOL DF_terminate;

@end

@implementation DFGenerator

+ (instancetype)operationFromBlock:(id)block ports:(NSArray *)ports
{
    return [[[self class] alloc] initWithGeneratorBlock:block ports:ports];
}

+ (void)terminateValueGeneration
{
    NSString *reason = [NSString stringWithFormat:@"Terminating Value Generation"];
    @throw [DFEndValueGenerationException exceptionWithName:NSStringFromClass([DFEndValueGenerationException class])
                                                            reason:reason
                                                          userInfo:nil];
}

+ (instancetype)generator
{
    return [self new];
}

- (instancetype)initWithGeneratorBlock:(id)generatorBlock ports:(NSArray *)ports
{
    self = [super init];
    if (self) {
        self.DF_executionObj = [[self class] DF_executionObjFromBlock:generatorBlock];
        self.DF_executionObj.executionBlock = generatorBlock;
        self.DF_inputPorts = ports;
    }
    return self;
}

- (BOOL)DF_execute
{
    __block id output = nil;
    __block BOOL result = NO;
    NSError *error = nil;
    if (!self.portErrorResolutionBlock) {
        error = [self DF_incomingPortErrors];
    }
    if (!error) {
        Execution_Class *executionObj = self.DF_executionObj;
        [self DF_prepareExecutionObj:executionObj];
        @try {
            //don't acquire lock when executing
            output = [executionObj execute];
        }
        @catch (NSException *DFOperationValueTerminationException) {
            self.DF_terminate = YES;
        }
        @catch (NSException *exception) {
            error = NSErrorFromException(exception);
        }
        @finally {
            [self DF_breakRefCycleForExecutionObj:self.DF_executionObj];
        }
    }
    if (error) {
        self.DF_error = error;
        self.DF_output = errorObject(error);
    }
    else if (!self.DF_terminate){
        self.DF_output = output;
        result = YES;
    }
    return result;
}

- (void)stop
{
    self.DF_terminate = YES;
}

- (void)next
{
    dispatch_block_t block = ^(void) {
        if (self.DF_state == OperationStateExecuting) {
            if (self.DF_terminate) {
                self.DF_state = OperationStateDone;
            }
            else if (![self DF_execute]) {
                self.DF_state = OperationStateDone;
            }
        }
    };
    [self DF_safelyExecuteBlock:block];
}

- (void)main
{
    dispatch_block_t block = ^(void) {
        if (self.DF_state != OperationStateExecuting) {
            return;
        }
        [self next];
    };
    [self DF_safelyExecuteBlock:block];
}

@end

@interface ArrayGenerator ()

@property (assign, nonatomic) NSUInteger DF_index;

@end

@implementation ArrayGenerator

+ (ArrayGenerator *)generator
{
    ArrayGenerator *generator = OperationFromBlock(self, ^(NSArray *array, ArrayGenerator *selfRef){
        id output = nil;
        NSUInteger index = selfRef.DF_index;
        if ((array.count == 0) || (index > (array.count - 1))) {
            selfRef.DF_terminate = YES;
        }
        else {
            output = array[index];
            index ++;
        }
        selfRef.DF_index = index;
        return output;
    });
    return generator;
}

@end

@implementation KeyValue

@end

@interface DictionaryGenerator ()

@property (assign, nonatomic) NSUInteger DF_index;

@property (strong, nonatomic) NSArray *DF_keys;

@end

@implementation DictionaryGenerator

+ (DictionaryGenerator *)generator
{
    DictionaryGenerator *generator = OperationFromBlock(self, ^(NSDictionary *dictionary, DictionaryGenerator *selfRef){
        NSUInteger index = selfRef.DF_index;
        NSArray *keys = selfRef.DF_keys;
        KeyValue *output = nil;
        if (!keys) {
            keys = [dictionary allKeys];
            selfRef.DF_keys = keys;
        }
        if (keys.count == 0 || (index > (keys.count - 1))) {
            selfRef.DF_terminate = YES;
        }
        else {
            id key = keys[index];
            id value = dictionary[key];
            output = [KeyValue new];
            output.key = key;
            output.value = value;
            index ++;
        }
        selfRef.DF_index = index;
        return output;
    });
    return generator;
}

@end

@interface SetGenerator ()

@property (assign, nonatomic) NSUInteger DF_index;

@property (strong, nonatomic) NSArray *DF_values;

@end

@implementation SetGenerator

+ (SetGenerator *)generator
{
    SetGenerator *generator = OperationFromBlock(self, ^(NSSet *set, SetGenerator *selfRef){
        NSUInteger index = selfRef.DF_index;
        NSArray *values = selfRef.DF_values;
        id output = nil;
        if (!values) {
            values = [set allObjects];
            selfRef.DF_values = values;
        }
        if ([values count] == 0 || (index > (values.count - 1))) {
            selfRef.DF_terminate = YES;
        }
        else {
            output = values[index];
            index ++;
        }
        selfRef.DF_index = index;
        return output;
    });
    return generator;
}

@end

@implementation SequenceGenerator

+ (instancetype)generator
{
    SequenceGenerator *generator = OperationFromBlock(self, ^(NSNumber *i, NSNumber *j, NSNumber *inc, DFGenerator *selfRef) {
        NSInteger value = [i integerValue];
        if (!isDFVoidObject(selfRef.DF_output)) {
            value = [selfRef.DF_output integerValue] + [inc integerValue];
        }
        if (value >= [j integerValue]) {
            selfRef.DF_terminate = YES;
        }
        return @(value);
    });
    return generator;
}

@end

@interface RepeatGenerator ()

@property (assign, nonatomic) NSUInteger DF_index;

@end

@implementation RepeatGenerator

+ (instancetype)generator
{
    RepeatGenerator *generator = OperationFromBlock(self, ^(id input, NSNumber *n, RepeatGenerator *selfRef) {
        if (selfRef.DF_index >= [n integerValue]) {
            selfRef.DF_terminate = YES;
        }
        selfRef.DF_index ++;
        return input;
    });
    return generator;
}

@end



