//
//  DFSplitterOperation.h
//  vf-hollywood
//
//  Created by Sinha, Gyanendra on 8/1/14.
//  Copyright (c) 2014 Conde Nast. All rights reserved.
//

#import "DFMapOperation.h"

@interface DFFlattenOperation : DFMapOperation

@property (strong, nonatomic) NSArray *input;

+ (DFFlattenOperation *)flattenOperation;

@end
