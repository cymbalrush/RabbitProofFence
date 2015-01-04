//
//  DFReduceOperation.h
//  vf-hollywood
//
//  Created by Sinha, Gyanendra on 6/23/14.
//  Copyright (c) 2014 Conde Nast. All rights reserved.
//

#import "DFReactiveOperation.h"

@interface DFReduceOperation : DFReactiveOperation

@property (readonly, nonatomic) id acc;

@property (strong, nonatomic) id seed;

- (instancetype)initWithReduceBlock:(id)reduceBlock ports:(NSArray *)ports;

@end
