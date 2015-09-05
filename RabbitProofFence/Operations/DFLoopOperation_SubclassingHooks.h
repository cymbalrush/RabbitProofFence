//
//  DFLoopOperation_SubclassingHooks.h

//
//  Created by Sinha, Gyanendra on 6/23/14.

//

#import "DFLoopOperation.h"
#import "DFMetaOperation_SubclassingHooks.h"

@interface DFLoopOperation ()

@property (strong, nonatomic) NSPredicate *DF_predicate;

@property (assign, nonatomic) NSUInteger DF_executionCount;

- (BOOL)DF_next;

@end
