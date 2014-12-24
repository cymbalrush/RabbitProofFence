//
//  OperationInfo.m
//  vf-hollywood
//
//  Created by Sinha, Gyanendra on 6/23/14.
//  Copyright (c) 2014 Conde Nast. All rights reserved.
//

#import "OperationInfo.h"
#import "DFOperation_SubclassingHooks.h"

@implementation OperationInfo

- (void)clean
{
    if (self.observationToken) {
        [self.operation safelyRemoveObserverWithBlockToken:self.observationToken];
        self.observationToken = nil;
    }
}

- (void)dealloc
{
    [self clean];
}

@end
