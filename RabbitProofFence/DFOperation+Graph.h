//
//  DFOperation+Visual.h
//  RabbitProofFence
//
//  Created by Sinha, Gyanendra on 11/7/14.
//  Copyright (c) 2014 Sinha, Gyanendra. All rights reserved.
//

#import "DFOperation.h"
#import <UIKit/UIKit.h>

@class DFNode;
@class DFPort;

@interface DFOperation (Graph)

@property (readonly, nonatomic) DFNode *visualRepresentation;

- (void)layoutNodesInView:(UIView *)view nodeSeparation:(CGPoint)separation;

@end
