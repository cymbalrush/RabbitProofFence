//
//  DFParallelOperation.h
//  vf-hollywood
//
//  Created by Sinha, Gyanendra on 6/23/14.
//  Copyright (c) 2014 Conde Nast. All rights reserved.
//

#import "DFReactiveOperation.h"

@interface DFParallelOperation : DFReactiveOperation

@property (assign, nonatomic) NSUInteger maxConcurrentOperations;

@property (assign, nonatomic) BOOL outputInOrder;

//will be called when an operation finishes, can be used to modify output or to introduce side effects
@property (copy, nonatomic) id(^processOutputForFinishedOperation)(DFOperation *operation);

@end
