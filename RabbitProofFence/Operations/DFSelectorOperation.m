//
//  DFSelectorOperation.m
//  RabbitProofFence
//
//  Created by Sinha, Gyanendra on 1/5/15.
//  Copyright (c) 2015 Sinha, Gyanendra. All rights reserved.
//

#import "DFSelectorOperation.h"
#import "DFOperation_SubclassingHooks.h"

@implementation DFSelectorOperation

+ (instancetype)operationFromBlock:(id)block ports:(NSArray *)ports
{
    methodNotSupported();
    return nil;
}

+ (instancetype)operation
{
    return [self new];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSArray *ports = @[@keypath(self.object), @keypath(self.selector)];
        self.DF_inputPorts = ports;
        id (^block)(id object, NSString *selector) = ^(id object, NSString *selector) {
            return [object valueForKey:selector];
        };
        self.executionBlock = block;
        [self DF_populateTypesFromBlock:block ports:ports];
    }
    return self;
}

@end
