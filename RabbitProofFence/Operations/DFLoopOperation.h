//
//  DFLoopOperation.h
//  vf-hollywood
//
//  Created by Sinha, Gyanendra on 6/23/14.
//  Copyright (c) 2014 Conde Nast. All rights reserved.
//

#import "DFMetaOperation.h"
#import "StreamOperation.h"

@interface DFLoopOperation : DFMetaOperation <StreamOperation>

@property (readonly, nonatomic) NSPredicate *predicate;

@property (copy, nonatomic) id retryBlock;

- (instancetype)initWithOperation:(DFOperation *)operation predicate:(NSPredicate *)predicate;

- (instancetype)initWithRetryBlock:(id)retryBlock ports:(NSArray *)ports;

@end
