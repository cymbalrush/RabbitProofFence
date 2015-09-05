//
//  DFPeriodicOperation.h

//
//  Created by Sinha, Gyanendra on 6/23/14.

//

#import "DFLoopOperation.h"

@interface DFPeriodicOperation : DFLoopOperation

@property (assign, nonatomic) NSTimeInterval waitInterval;

- (instancetype)initWithOperation:(DFOperation *)operation andWaitInterval:(NSTimeInterval)waitInterval;

- (void)setWaitIntervalAndStartNow:(NSTimeInterval)waitInterval;

@end
