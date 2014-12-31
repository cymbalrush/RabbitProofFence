//
//  DFLoopOperation_SubclassingHooks.h
//  vf-hollywood
//
//  Created by Sinha, Gyanendra on 6/23/14.
//  Copyright (c) 2014 Conde Nast. All rights reserved.
//

#import "DFLoopOperation.h"
#import "DFMetaOperation_SubclassingHooks.h"

@interface DFLoopOperation ()

@property (strong, nonatomic) NSPredicate *predicate;

@property (assign, nonatomic) NSUInteger executionCount;

- (BOOL)retry;

@end
