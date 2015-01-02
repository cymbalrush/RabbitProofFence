//
//  DFIdentityOperation.m
//  RabbitProofFence
//
//  Created by Sinha, Gyanendra on 11/20/14.
//  Copyright (c) 2014 Sinha, Gyanendra. All rights reserved.
//

#import "DFIdentityOperation.h"
#import "DFOperation_SubclassingHooks.h"

@implementation DFIdentityOperation

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.inputPorts = @[@keypath(self.input)];
        id(^block)(id input) = ^(id input) {
            return input;
        };
        self.executionObj = [[self class] executionObjFromBlock:block];
        self.executionObj.executionBlock = block;
    }
    return self;
}

@end