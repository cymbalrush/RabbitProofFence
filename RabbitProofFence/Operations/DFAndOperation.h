//
//  DFAndOperation.h
//  vf-hollywood
//
//  Created by Sinha, Gyanendra on 6/23/14.
//  Copyright (c) 2014 Conde Nast. All rights reserved.
//

#import "DFReactiveOperation.h"

@interface DFAndOperation : DFReactiveOperation 

@property (strong, nonatomic) NSArray *output;

+ (instancetype)andOperation:(NSArray *)ports;

- (instancetype)initWithPorts:(NSArray *)ports;

@end
