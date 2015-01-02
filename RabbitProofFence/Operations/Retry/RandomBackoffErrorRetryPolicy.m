//
//  RandomBackoffErrorRetryPolicy.h
//  vf-hollywood
//
//  Created by Sinha, Gyanendra on 6/23/14.
//  Copyright (c) 2014 Conde Nast. All rights reserved.
//

#import "RandomBackoffErrorRetryPolicy.h"

#define ARC4RANDOM_MAX 0x100000000

@interface RandomBackoffErrorRetryPolicy ()

@property (assign, nonatomic) double backOffFactor;

@property (assign, nonatomic) NSUInteger currentRetryCount;

@end

@implementation RandomBackoffErrorRetryPolicy

- (instancetype)initWithRetryCount:(NSUInteger)retryCount base:(double)base factor:(double)factor
{
    self = [super init];
    if (self) {
        _factor = factor;
        _base = base;
        _retryCount = retryCount;
        _backOffFactor = base;
    }
    return self;
}

- (BOOL)shouldRetry
{
    return self.currentRetryCount < self.retryCount;
}

- (NSTimeInterval)waitInterval
{
    return self.backOffFactor * ((double)arc4random() / ARC4RANDOM_MAX);
}

- (void)retried
{
    self.currentRetryCount ++;
    if (self.currentRetryCount < self.retryCount) {
        self.backOffFactor *= self.factor;
    }
}

- (id)copyWithZone:(NSZone *)zone
{
    RandomBackoffErrorRetryPolicy *policy = [super copyWithZone:zone];
    policy.retryCount = self.retryCount;
    policy.factor = self.factor;
    policy.base = self.base;
    return policy;
}

@end
