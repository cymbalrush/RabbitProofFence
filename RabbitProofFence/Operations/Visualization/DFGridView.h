//
//  DFGridView.h
//  RabbitProofFence
//
//  Created by Sinha, Gyanendra on 11/15/14.
//  Copyright (c) 2014 Sinha, Gyanendra. All rights reserved.
//

#import <UIKit/UIKit.h>
@class DFWorkspace;
@class DFNode;
@class DFPort;

@interface DFGridView : UIView

@property (weak, nonatomic) DFWorkspace *workspace;

@property (assign, nonatomic) CGPoint offset;

- (void)addNode:(DFNode *)node;

- (void)removeNode:(DFNode *)node;

- (void)clearConnectionLayerForPort:(DFPort *)port;

- (void)animateValueFlowFromPort:(DFPort *)fromPort toPort:(DFPort *)toPort;

@end
