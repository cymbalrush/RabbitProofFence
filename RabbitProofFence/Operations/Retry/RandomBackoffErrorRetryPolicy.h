//
//  RandomBackoffErrorRetryPolicy.h

//
//  Created by Sinha, Gyanendra on 6/23/14.

//

#import "ErrorRetryPolicy.h"

// RandomBackoffErrorRetryPolicy is based on a * random(0, 1), where 'a' starts with base and after each
// retry 'a' is multiplied by 'factor'
@interface RandomBackoffErrorRetryPolicy : ErrorRetryPolicy

//max number of retries
@property (assign, nonatomic) NSUInteger retryCount;

//base value to start
@property (assign, nonatomic) double base;

//after each retry waitInterval is multiplied by factor to generate next value
@property (assign, nonatomic) double factor;

/**
 * Designated initializer.
 * @param retryCount - number of retries
 * @param base - base value
 * @param factor - after each retry backOffFactor is multiplied by factor.
 * @return initialized instance of RandomBackoffErrorRetryPolicy
**/
- (id)initWithRetryCount:(NSUInteger)retryCount base:(double)base factor:(double)factor;

@end
