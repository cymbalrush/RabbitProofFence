//
//  ReactiveConnectionInfo.m
//  vf-hollywood
//
//  Created by Sinha, Gyanendra on 6/23/14.
//  Copyright (c) 2014 Conde Nast. All rights reserved.
//

#import "ReactiveConnectionInfo.h"
#import "DFOperation_SubclassingHooks.h"
#import "EXTNil.h"

@implementation ReactiveConnectionInfo

- (instancetype)init
{
    self = [super init];
    if (self) {
        _connectionCapacity = -1;
        _inputs = [NSMutableArray array];
    }
    return self;
}

- (void)addInput:(id)input
{
    input = (input == nil) ? [EXTNil null] : input;
    if (self.connectionCapacity == -1) {
        [self.inputs addObject:input];
    }
    else {
        int itemsToRemove = (int)([self.inputs count] + 1) - self.connectionCapacity;
        if (itemsToRemove > 0) {
            NSRange range = NSMakeRange(0, itemsToRemove);
            [self.inputs removeObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:range]];
        }
        [self.inputs addObject:input];
    }
}

- (void)clean
{
    if (self.propertyObservationToken) {
        [self.operation safelyRemoveObserverWithBlockToken:self.propertyObservationToken];
        self.propertyObservationToken = nil;
    }
    if (self.stateObservationToken) {
        [self.operation safelyRemoveObserverWithBlockToken:self.stateObservationToken];
        self.stateObservationToken = nil;
    }
    [self.inputs removeAllObjects];
}

- (NSString *)debugDescription
{
    return [NSString stringWithFormat:@"\n{property:%@ \n inputs: %@ \n operation:%@ \n}", self.connectedProperty,
            self.inputs,
            self.operation];
}

- (void)dealloc
{
    [self clean];
}

@end
