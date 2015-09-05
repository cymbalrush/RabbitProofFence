//
//  DependentOperationInfo.m

//
//  Created by Sinha, Gyanendra on 6/23/14.

//

#import "OperationInfo.h"
#import "DFOperation_SubclassingHooks.h"

@implementation OperationInfo

- (void)clean
{
    if (self.stateObservationToken) {
        [self.operation DF_safelyRemoveObserver:self.stateObservationToken];
        self.stateObservationToken = nil;
    }
    if (self.outputObservationToken) {
        [self.operation DF_safelyRemoveObserver:self.outputObservationToken];
        self.outputObservationToken = nil;
    }
}

- (void)dealloc
{
    [self clean];
}

@end
