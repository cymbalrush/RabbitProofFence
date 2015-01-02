//
//  LinearErrorRetryPolicy.m
//  vf-hollywood
//
//  Created by Sinha, Gyanendra on 6/23/14.
//  Copyright (c) 2014 Conde Nast. All rights reserved.
//

#import "LinearErrorRetryPolicy.h"

@interface LinearErrorRetryPolicy ()

@property (nonatomic, assign) NSUInteger currentRetryCount;

@end

@implementation LinearErrorRetryPolicy

- (instancetype)initWithRetryCount:(NSUInteger)retryCount base:(double)base factor:(double)factor
{
    self = [super init];
    if (self) {
        _retryCount = retryCount;
        _factor = factor;
        _base = base;
    }
    return self;
}

- (NSTimeInterval)waitInterval
{
    //ax + b
    return self.factor * self.currentRetryCount + self.base;
}

- (BOOL)shouldRetry
{
    return self.currentRetryCount < self.retryCount;
}

- (void)retried
{
    self.currentRetryCount++;
}

- (instancetype)copyWithZone:(NSZone *)zone
{
    LinearErrorRetryPolicy *policy = [super copyWithZone:zone];
    policy.retryCount = self.retryCount;
    policy.factor = self.factor;
    policy.base = self.base;
    return policy;
}

@end
