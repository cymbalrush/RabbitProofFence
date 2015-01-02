//
//  DFReduceOperation.h
//  vf-hollywood
//
//  Created by Sinha, Gyanendra on 6/23/14.
//  Copyright (c) 2014 Conde Nast. All rights reserved.
//

#import "DFReactiveOperation.h"

@interface DFReduceOperation : DFReactiveOperation

@property (strong, nonatomic) id accumulator;

@property (strong, nonatomic) id initialValue;

- (instancetype)initWithReduceBlock:(id)reduceBlock ports:(NSArray *)ports;

@end
