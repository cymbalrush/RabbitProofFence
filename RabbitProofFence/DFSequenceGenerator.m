//
//  DFLazyValueGenerator.m
//  vf-hollywood
//
//  Created by Sinha, Gyanendra on 6/23/14.
//  Copyright (c) 2014 Conde Nast. All rights reserved.
//

#import "DFSequenceGenerator.h"
#import "DFBackgroundOperation.h"
#import "DFMetaOperation_SubclassingHooks.h"
#import "DFVoidObject.h"

@interface DFOperationValueTerminationException : NSException

@end

@implementation DFOperationValueTerminationException

@end

@interface DFSequenceGenerator ()

@property (strong, nonatomic) Execution_Class *valueGeneratorObj;

@property (assign, nonatomic) BOOL terminate;

@end

@implementation DFSequenceGenerator

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

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.output = [DFVoidObject new];
    }
    return self;
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

- (void)generateNext
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

- (void)main
{
    dispatch_block_t block = ^(void) {
        if (self.state != OperationStateExecuting) {
            return;
        }
        if (!self.error) {
            [self generateNext];
            return;
        }
        self.output = [DFVoidObject new];
        [self done];
    };
    [self safelyExecuteBlock:block];
}

@end

@interface ArraySequenceGenerator ()

@property (assign, nonatomic) NSUInteger index;

@end

@implementation ArraySequenceGenerator

+ (ArraySequenceGenerator *)sequenceGenerator
{
    ArraySequenceGenerator *generator = OperationFromBlock(self, ^(NSArray *array, ArraySequenceGenerator *selfRef){
        id output = nil;
        NSUInteger index = selfRef.index;
        if ((![array isKindOfClass:[NSArray class]]) || ([array count] == 0) || (index > ([array count] - 1))) {
            selfRef.terminate = YES;
        }
        else {
            output = [array objectAtIndex:index];
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

@interface DictionarySequenceGenerator ()

@property (assign, nonatomic) NSUInteger index;

@property (strong, nonatomic) NSArray *keys;

@end

@implementation DictionarySequenceGenerator

+ (DictionarySequenceGenerator *)sequenceGenerator
{
    DictionarySequenceGenerator *generator = OperationFromBlock(self, ^(NSDictionary *dictionary, DictionarySequenceGenerator *selfRef){
        NSUInteger index = selfRef.index;
        NSArray *keys = selfRef.keys;
        KeyValue *output = nil;
        if (!keys) {
            keys = [dictionary allKeys];
            selfRef.keys = keys;
        }
        if ([keys count] == 0 || (index > ([keys count] - 1))) {
            selfRef.terminate = YES;
        }
        else {
            id key = [keys objectAtIndex:index];
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

