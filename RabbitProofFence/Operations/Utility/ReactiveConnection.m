//
//  ReactiveConnectionInfo.m

//
//  Created by Sinha, Gyanendra on 6/23/14.

//

#import "ReactiveConnection.h"
#import "DFOperation_SubclassingHooks.h"
#import "EXTNil.h"

@implementation ReactiveConnection

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
        NSInteger itemsToRemove = self.inputs.count - self.connectionCapacity;
        if (itemsToRemove > 0) {
            NSRange range = NSMakeRange(0, itemsToRemove);
            [self.inputs removeObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:range]];
        }
        [self.inputs addObject:input];
    }
}

- (void)clean
{
    if (self.stateObservationToken) {
        [self.operation DF_safelyRemoveObserver:self.stateObservationToken];
        self.stateObservationToken = nil;
    }
    if (self.propertyObservationToken) {
        [self.operation DF_safelyRemoveObserver:self.propertyObservationToken];
        self.propertyObservationToken = nil;
    }
    [self.inputs removeAllObjects];
}

- (NSString *)debugDescription
{
    return [NSString stringWithFormat:@"\n{property:%@ \n inputs: %@ \n operation:%@ \n}", self.fromPort,
            self.inputs,
            self.operation];
}

- (void)dealloc
{
    [self clean];
}

@end
