//
//  DFBackgroundOperation.m

//
//  Created by Sinha, Gyanendra on 6/23/14.

//

#import "DFBackgroundOperation.h"

NSString * const DFBackgroundOperationQueueName = @"com.operations.backgroundQueue";

@implementation DFBackgroundOperation

+ (NSOperationQueue *)operationQueue
{
    static NSOperationQueue *queue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = [[NSOperationQueue alloc] init];
        [queue setMaxConcurrentOperationCount:NSOperationQueueDefaultMaxConcurrentOperationCount];
    });
    return queue;
}

@end
