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

@interface DFOperationValueTerminationException : NSException

@end

@implementation DFOperationValueTerminationException

@end

@interface DFGenerator ()

@property (assign) BOOL terminate;

@end

@implementation DFGenerator

+ (instancetype)operationFromBlock:(id)block ports:(NSArray *)ports
{
    return [[[self class] alloc] initWithGeneratorBlock:block ports:ports];
}

+ (void)terminateValueGeneration
{
    NSString *reason = [NSString stringWithFormat:@"Terminating Value Generation"];
    @throw [DFOperationValueTerminationException exceptionWithName:NSStringFromClass([DFOperationValueTerminationException class])
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
        self.executionObj = [[self class] executionObjFromBlock:generatorBlock];
        self.executionObj.executionBlock = generatorBlock;
        self.inputPorts = ports;
    }
    return self;
}

- (void)next
{
    Execution_Class *executionObj = self.executionObj;
    dispatch_block_t block = ^(void) {
        if (self.state == OperationStateExecuting) {
            [self prepareExecutionObj:executionObj];
            @try {
                id output = [executionObj execute];
                if (self.terminate) {
                    [self done];
                }
                else {
                    self.output = output;
                }
            }
            @catch (DFOperationValueTerminationException *exception) {
                [self done];
            }
            @catch (NSException *exception) {
                self.error = NSErrorFromException(exception);
                [self done];
            }
            @finally {
                [self breakRefCycleForExecutionObj:executionObj];
            }
        }
    };
    [self safelyExecuteBlock:block];
}

- (void)stop
{
    self.terminate = YES;
}

- (void)main
{
    dispatch_block_t block = ^(void) {
        if (self.state != OperationStateExecuting) {
            return;
        }
        if (!self.error) {
            [self next];
            return;
        }
        [self done];
    };
    [self safelyExecuteBlock:block];
}

@end

@interface ArrayGenerator ()

@property (assign, nonatomic) NSUInteger index;

@end

@implementation ArrayGenerator

+ (ArrayGenerator *)generator
{
    ArrayGenerator *generator = OperationFromBlock(self, ^(NSArray *array, ArrayGenerator *selfRef){
        id output = nil;
        NSUInteger index = selfRef.index;
        if ((array.count == 0) || (index > (array.count - 1))) {
            selfRef.terminate = YES;
        }
        else {
            output = array[index];
            index ++;
        }
        selfRef.index = index;
        return output;
    });
    return generator;
}

@end

@implementation KeyValue

@end

@interface DictionaryGenerator ()

@property (assign, nonatomic) NSUInteger index;

@property (strong, nonatomic) NSArray *keys;

@end

@implementation DictionaryGenerator

+ (DictionaryGenerator *)generator
{
    DictionaryGenerator *generator = OperationFromBlock(self, ^(NSDictionary *dictionary, DictionaryGenerator *selfRef){
        NSUInteger index = selfRef.index;
        NSArray *keys = selfRef.keys;
        KeyValue *output = nil;
        if (!keys) {
            keys = [dictionary allKeys];
            selfRef.keys = keys;
        }
        if (keys.count == 0 || (index > (keys.count - 1))) {
            selfRef.terminate = YES;
        }
        else {
            id key = keys[index];
            id value = dictionary[key];
            output = [KeyValue new];
            output.key = key;
            output.value = value;
            index ++;
        }
        selfRef.index = index;
        return output;
    });
    return generator;
}

@end

@interface SetGenerator ()

@property (assign, nonatomic) NSUInteger index;

@property (strong, nonatomic) NSArray *values;

@end

@implementation SetGenerator

+ (SetGenerator *)generator
{
    SetGenerator *generator = OperationFromBlock(self, ^(NSSet *set, SetGenerator *selfRef){
        NSUInteger index = selfRef.index;
        NSArray *values = selfRef.values;
        id output = nil;
        if (!values) {
            values = [set allObjects];
            selfRef.values = values;
        }
        if ([values count] == 0 || (index > (values.count - 1))) {
            selfRef.terminate = YES;
        }
        else {
            output = values[index];
            index ++;
        }
        selfRef.index = index;
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
        if (!isVoid(selfRef.output)) {
            value = [selfRef.output integerValue] + [inc integerValue];
        }
        if (value > [j integerValue]) {
            selfRef.terminate = YES;
        }
        return @(value);
    });
    return generator;
}

@end

@interface RepeatGenerator ()

@property (assign, nonatomic) NSUInteger index;

@end

@implementation RepeatGenerator

+ (instancetype)generator
{
    RepeatGenerator *generator = OperationFromBlock(self, ^(id input, NSNumber *n, RepeatGenerator *selfRef) {
        if (selfRef.index >= [n integerValue]) {
            selfRef.terminate = YES;
        }
        selfRef.index ++;
        return input;
    });
    return generator;
}

@end



