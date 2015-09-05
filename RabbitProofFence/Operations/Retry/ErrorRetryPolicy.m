//
//  ErrorRetryPolicy.m

//
//  Created by Sinha, Gyanendra on 6/23/14.

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
