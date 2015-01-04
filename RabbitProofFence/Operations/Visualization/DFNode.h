//
//  DFNode.h
//  RabbitProofFence
//
//  Created by Sinha, Gyanendra on 11/6/14.
//  Copyright (c) 2014 Sinha, Gyanendra. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DFPort;
@class DFOperation;
@class DFWorkspace;

@interface DFNodeInfo : NSObject <NSCopying>

@property (strong, nonatomic) NSString *name;

@property (strong, nonatomic) NSArray *inputPorts;

@property (strong, nonatomic) NSArray *outputPorts;

@property (strong, nonatomic) UIColor *nodeColor;

@end

@interface DFNode : UIView

+ (instancetype)nodeWithInfo:(DFNodeInfo *)info;

@property (readonly, nonatomic) DFNodeInfo *info;

@property (strong, nonatomic) DFOperation *operation;

@property (readonly, nonatomic) NSArray *inputPorts;

@property (readonly, nonatomic) NSArray *outputPorts;

@property (readonly, nonatomic) NSArray *ports;

@property (readonly, nonatomic) NSSet *connectedNodes;

@property (assign, nonatomic) NSUInteger level;

@property (copy, nonatomic) DFOperation *(^operationCreationBlock)();

@property (weak, nonatomic) DFWorkspace *workspace;

@property (readonly, nonatomic) id result;

@property (readonly, nonatomic) BOOL isReactive;

- (DFPort *)portForName:(NSString *)name;

- (DFPort *)portForTouchPoint:(CGPoint)point;

- (BOOL)canDragWithPoint:(CGPoint)point;

- (void)prepare;

- (void)execute;

- (void)reset;

- (NSSet *)connectedNodes;

- (Class)portType:(NSString *)port;

- (BOOL)canConnectPort:(DFPort *)port toPort:(DFPort *)toPort;

@end

@interface DFNode (SubClassingHooks)

- (void)prepare_:(NSMutableSet *)preparedNodes;

@end
