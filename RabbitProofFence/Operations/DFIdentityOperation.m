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
        self.DF_inputPorts = @[@keypath(self.input)];
        id(^block)(id input) = ^(id input) {
            return input;
        };
        self.DF_executionObj = [[self class] DF_executionObjFromBlock:block];
        self.DF_executionObj.executionBlock = block;
        [self DF_populateTypesFromBlock:block ports:self.DF_inputPorts];
    }
    return self;
}

@end
