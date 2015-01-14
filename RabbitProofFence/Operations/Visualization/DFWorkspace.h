//
//  DFWorkSpace.h
//  RabbitProofFence
//
//  Created by Sinha, Gyanendra on 11/7/14.
//  Copyright (c) 2014 Sinha, Gyanendra. All rights reserved.
//

#import <UIKit/UIKit.h>


//Inspired from https://github.com/krzysztofzablocki/KZNodes

@class DFPort;
@class DFNode;
@class DFOperation;

@interface DFWorkspace : UIView

+ (void)registerOperationCreationBlock:(DFOperation *(^)(void))creationBlock forName:(NSString *)name;

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

- (void)toggleLeftPane;

@end
