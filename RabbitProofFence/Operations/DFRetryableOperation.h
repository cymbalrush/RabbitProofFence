//
//  DFRetryableOperation.h

//
//  Created by Sinha, Gyanendra on 6/23/14.

//

#import "DFMetaOperation.h"

@class ErrorRetryPolicy;

@interface DFRetryableOperation : DFMetaOperation

/*
 In case of error a retry policy is picked.
 @params retryPolicy - Retry policy to be added. Don't call when operation starts exection.
*/
- (void)addErrorRetryPolicy:(ErrorRetryPolicy *)retryPolicy;

/*
 @params:
 In case of error a retry policy is picked.
 retryPolicies: Set of retry policies to be added. Don't call when operation start execution.
 */
- (void)addErrorRetryPolicies:(NSArray *)retryPolicies;

/*
 Remove retry policy which was previously added.
 @params:
 retryPolicy: Retry policy to be removed. Don't call when operation starts exection.
 */
- (void)removeErrorRetryPolicy:(ErrorRetryPolicy *)retryPolicy;

/*
 Remove retry policies which were previously added.
 @params:
 retryPolicies: Retry policies to be removed. Don't call when operation starts exection.
 */
- (void)removeErrorRetryPolicies:(NSArray *)retryPolicies;

/*
 If a retry policy exists for error then it's returned otherwise returns nil. Loops through all policies until finds one registered for error.

 @params:
 error: NSError object.
 @return:
 retry policy
 */
- (ErrorRetryPolicy *)retryPolicyForError:(NSError *)error;

@end
