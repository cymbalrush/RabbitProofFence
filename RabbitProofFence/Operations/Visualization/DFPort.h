//
//  DFSocket.h
//  RabbitProofFence
//
//  Created by Sinha, Gyanendra on 11/6/14.
//  Copyright (c) 2014 Sinha, Gyanendra. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DFNode;

typedef NS_ENUM(NSUInteger, DFPortType) {
    DFPortTypeInput = 0,
    DFPortTypeOutput = 1
};

@interface DFPortInfo : NSObject <NSCopying>

@property (strong, nonatomic) NSString *name;

@property (strong, nonatomic) Class dataType;

@property (assign, nonatomic) DFPortType portType;

@end

@interface DFPort : UIView

+ (instancetype)portWithInfo:(DFPortInfo *)info;

@property (strong,  nonatomic) DFPortInfo *info;

@property (weak, nonatomic) DFNode *node;

@property (strong, nonatomic) DFPort *connectedPort;

@property (readonly, nonatomic) NSString *name;

@property (readonly, nonatomic) DFPortType portType;

@property (readonly, nonatomic) Class dataType;

@property (readonly, nonatomic) CGPoint socketCenter;

@property (strong, nonatomic) CAShapeLayer *connectionLayer;

@property (strong, nonatomic) NSMutableSet *connections;

- (void)removeConnectionToPort:(DFPort *)port;

- (BOOL)canConnectToPort:(DFPort *)port;

- (BOOL)connectToPort:(DFPort *)port;

- (void)setCompatible:(BOOL)isCompatible;

- (void)reset;

@end
