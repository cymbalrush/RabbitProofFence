//
//  DFFilterOperation.h
//  vf-hollywood
//
//  Created by Sinha, Gyanendra on 6/23/14.
//  Copyright (c) 2014 Conde Nast. All rights reserved.
//

#import "DFReactiveOperation.h"

@interface DFFilterOperation : DFReactiveOperation

@property (strong, nonatomic) id input;

- (instancetype)initWithFilterBlock:(BOOL (^)(id input))filterBlock;

- (void)connectWithOperation:(DFOperation *)operation;

@end
