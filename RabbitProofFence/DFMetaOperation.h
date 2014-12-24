//
//  DFMetaOperation.h
//  vf-hollywood
//
//  Created by Sinha, Gyanendra on 6/23/14.
//  Copyright (c) 2014 Conde Nast. All rights reserved.
//

#import "DFOperation.h"

@interface DFMetaOperation : DFOperation

@property (readonly, nonatomic) DFOperation *operation;

- (instancetype)initWithOperation:(DFOperation *)operation;

+ (instancetype)operationFromOperation:(DFOperation *)operation;

@end
