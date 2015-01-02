//
//  ErrorRetryPolicy.m
//  vf-hollywood
//
//  Created by Sinha, Gyanendra on 6/23/14.
//  Copyright (c) 2014 Conde Nast. All rights reserved.
//

#import "ErrorRetryPolicy.h"

@implementation ErrorRetryPolicy

- (BOOL)shouldRetry
{
    return NO;
}

- (NSTimeInterval)waitInterval
{
    return 0;
}

- (void)retried
{}

- (BOOL)registeredForError:(NSError *)error
{
    if (self.errorRegistrationBlock) {
        return self.errorRegistrationBlock(error);
    }
    return NO;
}

- (instancetype)copyWithZone:(NSZone *)zone
{
    ErrorRetryPolicy *policy = [[[self class] allocWithZone:zone] init];
    policy.errorRegistrationBlock = self.errorRegistrationBlock;
    return policy;
}

@end
