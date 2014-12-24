//
//  DFWaitOperation.h
//  vf-hollywood
//
//  Created by Sinha, Gyanendra on 6/23/14.
//  Copyright (c) 2014 Conde Nast. All rights reserved.
//

#import "DFMetaOperation.h"

@interface DFWaitOperation : DFMetaOperation

@property (assign, nonatomic) NSTimeInterval waitInterval;

- (instancetype)initWithOperation:(DFOperation *)operation andWaitInterval:(NSTimeInterval)waitInterval;

@end
