//
//  ErrorRetryPolicy.h
//  vf-hollywood
//
//  Created by Sinha, Gyanendra on 6/23/14.
//  Copyright (c) 2014 Conde Nast. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ErrorRetryPolicy : NSObject <NSCopying>

//wait interval before retrying
@property (readonly, nonatomic) NSTimeInterval waitInterval;

//returns YES if policy is defined for error otherwise NO
@property (copy, nonatomic) BOOL (^errorRegistrationBlock)(NSError *error);

//returns YES if policy allows retrying otherwise NO
- (BOOL)shouldRetry;

//should be called after making a retry
- (void)retried;

@end
