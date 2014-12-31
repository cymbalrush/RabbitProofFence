//
//  DFObjectSplitter.m
//  vf-hollywood
//
//  Created by Sinha, Gyanendra on 7/25/14.
//  Copyright (c) 2014 Conde Nast. All rights reserved.
//

#import "DFLiftOperation.h"
#import "DFOperation_SubclassingHooks.h"

@implementation DFLiftOperation

+ (instancetype)operationFromPorts:(NSArray *)ports
{
    //ignore block
    return [[self alloc] initWithPorts:ports];
}

+ (instancetype)operationFromBlock:(id)block ports:(NSArray *)ports
{
    //ignore block
    return [[self alloc] initWithPorts:ports];
}

- (instancetype)initWithPorts:(NSArray *)ports
{
    self = [super init];
    if (self) {
        if ([ports indexOfObject:@keypath(self.object)] == NSNotFound) {
            ports = [ports arrayByAddingObject:@keypath(self.object)];
        }
        self.inputPorts = [ports copy];
        self.executionObj = [Execution_Class instanceForNumberOfArguments:[self.inputPorts count]];
    }
    return self;
}

- (instancetype)initWithObject:(id<NSObject>)object ports:(NSArray *)ports
{
    self = [self initWithPorts:ports];
    self.object = object;
    [self excludePortFromFreePorts:@keypath(self.object)];
    return self;
}

- (void)execute
{
      dispatch_block_t block = ^(void) {
        if (self.state == OperationStateExecuting) {
            if (!self.error) {
                if (self.object) {
                    NSMutableArray *ports = [self.inputPorts mutableCopy];
                    [ports removeObject:@keypath(self.object)];
                    [ports enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                        NSString *port = obj;
                        @try {
                            if ([self.propertiesSet containsObject:port]) {
                                [self.object setValue:[self valueForKey:obj] forKey:port];
                            }
                            else {
                                [self setValue:[self.object valueForKey:port] forKey:port];
                            }
                        }
                        @catch (NSException *exception) {}
                    }];
                }
            }
            if (!self.isCancelled) {
                self.output = self.object;
            }
            [self done];
        }
    };
    [self safelyExecuteBlock:block];
}

@end
