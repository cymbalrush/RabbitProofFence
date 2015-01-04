//
//  DFAggregatorOperation.h
//  vf-hollywood
//
//  Created by Sinha, Gyanendra on 6/23/14.
//  Copyright (c) 2014 Conde Nast. All rights reserved.
//

#import "DFReactiveOperation.h"

@interface DFAggregatorOperation : DFReactiveOperation

@property (strong, nonatomic) id input;

@property (readonly, nonatomic) NSArray *output;

+ (instancetype)aggregator;

@end
