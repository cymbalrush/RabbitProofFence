//
//  DFWorkSpace.h
//  RabbitProofFence
//
//  Created by Sinha, Gyanendra on 11/7/14.
//  Copyright (c) 2014 Sinha, Gyanendra. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DFPort;
@class DFNode;
@class DFOperation;

@interface DFWorkspace : UIView

+ (void)registerOpertaionCreationBlock:(DFOperation *(^)(void))creationBlock forName:(NSString *)name;

+ (void)removeOperationCreationBlockForName:(NSString *)name;

+ (NSArray *)activeWorkSpaces;

+ (instancetype)workspaceWithBounds:(CGRect)bounds;

- (void)pressedPort:(DFPort *)port;

- (void)addNode:(DFNode *)node;

- (void)removeNode:(DFNode *)node;

- (void)executeNode:(DFNode *)node;

- (void)makePatch:(NSString *)name node:(DFNode *)node;

- (void)breakConnectionFromPort:(DFPort *)outputPort toPort:(DFPort *)inputPort;

- (void)displayResult:(id)result ofNode:(DFNode *)node;

@end
