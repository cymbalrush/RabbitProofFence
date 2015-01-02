//
//  LinearErrorRetryPolicy.h
//  vf-hollywood
//
//  Created by Sinha, Gyanendra on 6/23/14.
//  Copyright (c) 2014 Conde Nast. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ErrorRetryPolicy.h"

// LinearErrorRetryPolicy is based on ax+b, where a is factor and b is base.
@interface LinearErrorRetryPolicy : ErrorRetryPolicy

@property (assign, nonatomic) NSUInteger retryCount;
@property (assign, nonatomic) double base;
@property (assign, nonatomic) double factor;

/*
 Designated initializer. 
 @params:
 retryCount : Number of retries.
 base: In 'ax + b', base is 'b'
 factor: In 'ax + b', factor is 'a'
 @return:
 Returns an instance of LinearErrorRetryPolicy
*/
- (id)initWithRetryCount:(NSUInteger)retryCount base:(double)base factor:(double)factor;

@end
