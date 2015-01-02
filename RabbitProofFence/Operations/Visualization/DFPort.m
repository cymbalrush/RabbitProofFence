//
//  DFSocket.m
//  RabbitProofFence
//
//  Created by Sinha, Gyanendra on 11/6/14.
//  Copyright (c) 2014 Sinha, Gyanendra. All rights reserved.
//

#import "DFPort.h"
#import "DFNode.h"
#import "DFWorkspace.h"

#define NSUINT_BIT (CHAR_BIT * sizeof(NSUInteger))
#define NSUINTROTATE(val, howmuch) ((((NSUInteger)val) << howmuch) | (((NSUInteger)val) >> (NSUINT_BIT - howmuch)))

@implementation DFPortInfo

- (instancetype)copyWithZone:(NSZone *)zone
{
    DFPortInfo *info = [[self class] new];
    info.name = [self.name copy];
    info.dataType = self.dataType;
    info.portType = self.portType;
    return info;
}

- (BOOL)isEqual:(id)object
{
    if (self == object) {
        return YES;
    }
    DFPort *port = object;
    return [port isKindOfClass:[DFPortInfo class]] &&
           [port.dataType isEqual:self.dataType] &&
           [port.name isEqualToString:self.name] &&
           port.portType == self.portType;
}

- (NSUInteger)hash
{
    return NSUINTROTATE([self.name hash], NSUINT_BIT / 2) ^ [self.dataType hash] ^ self.portType;
}

@end

@interface DFPort ()

@property (assign, nonatomic) CGFloat extraSpace;

@property (weak, nonatomic) IBOutlet UILabel *label;

@property (weak, nonatomic) IBOutlet UIView *containerView;

@property (weak, nonatomic) IBOutlet UIButton *socketButton;

@end

@implementation DFPort

+ (UINib *)matchingNibForPortType:(DFPortType)type
{
    NSString *nibName = [NSString stringWithFormat:@"%@_%@", NSStringFromClass(self.class), type == DFPortTypeInput ? @"Input" : @"Output"];
    
    if ([[NSBundle mainBundle] pathForResource:nibName ofType:@"nib"]) {
        return [UINib nibWithNibName:nibName bundle:[NSBundle mainBundle]];
    }
    
    nibName = [NSString stringWithFormat:@"%@_%@", NSStringFromClass(DFPort.class), type == DFPortTypeInput ? @"Input" : @"Output"];
    return [UINib nibWithNibName:nibName bundle:[NSBundle bundleForClass:self.class]];
}

+ (instancetype)portWithInfo:(DFPortInfo *)info
{
    UINib *nib = [self matchingNibForPortType:info.portType];
    DFPort *port = [self new];
    UIView *containerView = [[nib instantiateWithOwner:port options:nil] firstObject];
    port.bounds = containerView.bounds;
    [port addSubview:containerView];
    if (!port) {
        return nil;
    }
    [port setupPortWithInfo:info];
    return port;
}

- (void)reset
{
    if (self.connectedPort) {
        [self.node.workspace breakConnectionFromPort:self.connectedPort toPort:self];
    }
    [self.connections enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        [self.node.workspace breakConnectionFromPort:self toPort:obj];
    }];
}

- (void)dealloc
{
    [self reset];
}

- (void)setupPortWithInfo:(DFPortInfo *)info
{
    self.info = [info copy];
    self.connections = [NSMutableSet new];
    self.extraSpace = CGRectGetWidth(self.bounds) - CGRectGetWidth(self.label.bounds);
    
    self.label.text = [self.info.name uppercaseString];
    self.socketButton.adjustsImageWhenDisabled = NO;
    self.socketButton.adjustsImageWhenHighlighted = NO;
    self.socketButton.enabled = NO;
    
    [self sizeToFit];
}

- (NSString *)name
{
    return self.info.name;
}

- (DFPortType)portType
{
    return self.info.portType;
}

- (Class)dataType
{
    return self.info.dataType;
}

- (BOOL)connectToPort:(DFPort *)port
{
    if ([self canConnectToPort:port]) {
        [self.connections addObject:port];
        port.connectedPort = self;
        return YES;
    }
    return NO;
}

- (void)removeConnectionToPort:(DFPort *)port
{
    [(NSMutableSet *)self.connections removeObject:port];
    port.connectedPort = nil;
    [port.connectionLayer removeFromSuperlayer];
    port.connectionLayer = nil;
}

- (void)setConnectedPort:(DFPort *)connectedPort
{
    [self.connections removeAllObjects];
    if (connectedPort) {
        [self.connections addObject:connectedPort];
    }
    [UIView transitionWithView:self.socketButton.imageView
                      duration:0.25
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
        BOOL connected = connectedPort != nil;
        self.socketButton.selected = connected;
        self.socketButton.enabled = connected;
    } completion:nil];
}

- (DFPort *)connectedPort
{
    return [self.connections anyObject];
}

- (IBAction)pressedSocket:(id)sender
{
   [self.node.workspace pressedPort:self];
}

- (DFPort *)sourceSocket
{
    return [self.connections anyObject];
}

- (CGPoint)socketCenter
{
    return self.socketButton.center;
}

- (BOOL)canConnectToPort:(DFPort *)port
{
    return [self.dataType isSubclassOfClass:port.dataType] && port.portType == DFPortTypeInput && self.portType == DFPortTypeOutput;
}

- (void)setCompatible:(BOOL)isCompatible
{
    [UIView transitionWithView:self.socketButton.imageView
                      duration:0.3
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
                        self.socketButton.imageView.alpha = isCompatible ? 1.0f : 0.1f;}
                    completion:nil];
}

- (CGSize)sizeThatFits:(CGSize)size
{
    CGSize labelSize = [self.label sizeThatFits:size];
    labelSize.width += self.extraSpace;
    CGSize s = [super sizeThatFits:size];
    s.width = labelSize.width;
    return s;
}


@end
