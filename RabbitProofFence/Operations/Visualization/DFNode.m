//
//  DFNode.m
//  RabbitProofFence
//
//  Created by Sinha, Gyanendra on 11/6/14.
//  Copyright (c) 2014 Sinha, Gyanendra. All rights reserved.
//

#import "DFNode.h"
#import "DFPort.h"
#import "DFWorkspace.h"
#import "DFOperation.h"

#import "NSArray+Utility.h"
#import "EXTKeyPathCoding.h"
#import "EXTScope.h"
#import "NSObject+BlockObservation.h"
#import "DFOperation_SubclassingHooks.h"
#import "DFReactiveOperation.h"

@implementation DFNodeInfo

- (instancetype)copyWithZone:(NSZone *)zone
{
    DFNodeInfo *info = [[self class] new];
    info.name = [self.name copy];
    info.nodeColor = self.nodeColor;
    info.inputPorts = [self.inputPorts map:^id(id obj, NSUInteger idx) {
        return [(NSObject *)obj copy];
    }];
    info.outputPorts = [self.outputPorts map:^id(id obj, NSUInteger idx) {
        return [(NSObject *)obj copy];
    }];
    return info;
}

@end

@interface DFNode ()

@property (weak, nonatomic) IBOutlet UILabel *label;
@property (weak, nonatomic) IBOutlet UIView *containerView;

@property (assign, nonatomic) NSUInteger portVerticalSpacing;
@property (assign, nonatomic) NSUInteger portHorizontalSpacing;

@property (strong, nonatomic) DFNodeInfo *info;

@property (strong, nonatomic) UIImageView *gearView;
@property (strong, nonatomic) AMBlockToken *stateObservationToken;

@property (strong, nonatomic) id result;

@end

@implementation DFNode

+ (UINib *)matchingNib
{
    if ([[NSBundle mainBundle] pathForResource:NSStringFromClass(self.class) ofType:@"nib"]) {
        return [UINib nibWithNibName:NSStringFromClass(self.class) bundle:[NSBundle mainBundle]];
    }
    
    if ([[NSBundle mainBundle] pathForResource:NSStringFromClass(self.class) ofType:@"nib"]) {
        return [UINib nibWithNibName:NSStringFromClass(self.class) bundle:[NSBundle bundleForClass:self.class]];
    }
    
    return [UINib nibWithNibName:NSStringFromClass(DFNode.class) bundle:[NSBundle bundleForClass:self.class]];
}

+ (instancetype)nodeWithInfo:(DFNodeInfo *)info
{
    UINib *nib = [self matchingNib];
    DFNode *node = [self new];
    UIView *containerView = [[nib instantiateWithOwner:node options:nil] firstObject];
    node.bounds = containerView.bounds;
    [node addSubview:containerView];
    if (!node) {
        return nil;
    }
    [node setupNodeWithInfo:info];
    return node;
}

- (void)reset
{
    [self cancel];
    [self.ports enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        DFPort *port = obj;
        [port reset];
    }];
}

- (void)dealloc
{
    [self reset];
}

NS_INLINE void addPortToNode(DFPortInfo *portInfo, DFNode *node)
{
    DFPort *port = [DFPort portWithInfo:portInfo];
    [port sizeToFit];
    port.node = node;
    [node addSubview:port];
}

- (void)setupNodeWithInfo:(DFNodeInfo *)info
{
    self.info = [info copy];
    self.label.text = [NSString stringWithFormat:@" %@", [info.name uppercaseString]];
    [self sizeToFit];
    self.containerView.backgroundColor = info.nodeColor;
    //set up layer
    self.layer.shadowOpacity = 0.75;
    self.layer.shadowColor = info.nodeColor.CGColor;
    self.layer.shadowOffset = CGSizeMake(0, 1);
    
    
    //add recognizer
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(nodeTapped:)];
    [self addGestureRecognizer:tapRecognizer];
    
    self.portVerticalSpacing = 5;
    self.portHorizontalSpacing = 5;
    
    [info.inputPorts enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        addPortToNode(obj, self);
    }];
    
    [info.outputPorts enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        addPortToNode(obj, self);
    }];
    [self sizeToFit];
}

- (NSArray *)inputPorts
{
    return [self.info.inputPorts map:^id(id obj, NSUInteger idx) {
        DFPortInfo *info = obj;
        return [self portForInfo:info];
    }];
}

- (NSArray *)outputPorts
{
    return [self.info.outputPorts map:^id(id obj, NSUInteger idx) {
        DFPortInfo *info = obj;
        return [self portForInfo:info];
    }];
}

- (NSArray *)ports
{
    NSMutableArray *ports = [NSMutableArray new];
    [ports addObjectsFromArray:self.inputPorts];
    [ports addObjectsFromArray:self.outputPorts];
    return ports;
}

- (DFPort *)portForInfo:(DFPortInfo *)info
{
    if (!info) {
        return nil;
    }
    __block DFPort *result = nil;
    [self.subviews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        DFPort *port = obj;
        if ([port isKindOfClass:[DFPort class]] && [port.info isEqual:info]) {
            result = port;
            *stop = YES;
        }
    }];
    return result;
}

NS_INLINE DFPortInfo *infoForName(NSArray *infos, NSString *name)
{
    __block DFPortInfo *result = nil;
    [infos enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        DFPortInfo *info = obj;
        if ([info.name isEqualToString:name]) {
            result = info;
            *stop = YES;
        }
    }];
    return result;
}

- (DFPortInfo *)infoForName:(NSString *)name
{
    if (name.length == 0) {
        return nil;
    }
    DFPort *port = nil;
    DFPortInfo *info = infoForName([self.inputPorts valueForKey:@keypath(port.info)], name);
    return (info != nil) ? info : infoForName([self.outputPorts valueForKey:@keypath(port.info)], name);
}

- (DFPort *)portForName:(NSString *)name
{
    return [self portForInfo:[self infoForName:name]];
}

NS_INLINE DFPort *portForTouchPoint(CGPoint point, CGFloat margin, NSArray *ports)
{
    __block DFPort *port = nil;
    [ports enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CGRect frame = [obj frame];
        if (CGRectContainsPoint(CGRectInset(frame, -margin, -margin), point)) {
            port = obj;
            *stop = YES;
        }
    }];
    return port;
}

- (DFPort *)portForTouchPoint:(CGPoint)point
{
    DFPort *port = portForTouchPoint(point, 10, self.inputPorts);
    return port != nil ? port : portForTouchPoint(point, 10, self.outputPorts);
}

- (BOOL)canDragWithPoint:(CGPoint)point
{
    if ([self portForTouchPoint:point]) {
        return NO;
    }
    
    return CGRectContainsPoint(self.bounds, point);
}

- (CGSize)intrinsicContentSize
{
    __block CGFloat inputHeight = 0;
    [self.inputPorts enumerateObjectsUsingBlock:^(DFPort *port, NSUInteger idx, BOOL *stop) {
        inputHeight += CGRectGetHeight(port.bounds) + self.portVerticalSpacing;
    }];
    __block CGFloat outputHeight = 0;
    [self.outputPorts enumerateObjectsUsingBlock:^(DFPort *port, NSUInteger idx, BOOL *stop) {
        outputHeight += CGRectGetHeight(port.bounds) + self.portVerticalSpacing;
    }];
    
    __block CGFloat maxY = 0;
    [self.containerView.subviews enumerateObjectsUsingBlock:^(UIView *subview, NSUInteger idx, BOOL *stop) {
        if ([subview isKindOfClass:DFPort.class]) {
            return;
        }
        maxY = MAX(maxY, CGRectGetMaxY(subview.frame));
    }];
    
    return CGSizeMake(200, MAX(maxY, (MAX(inputHeight, outputHeight) + self.portStartYPosition)) + self.portVerticalSpacing);
}

- (NSUInteger)portStartYPosition
{
    const NSUInteger initialOffset = 8;
    return (NSUInteger)(roundf(CGRectGetMaxY(self.label.frame) + initialOffset));
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    __block CGFloat yPosition = self.portStartYPosition;
    [self.inputPorts enumerateObjectsUsingBlock:^(DFPort *port, NSUInteger idx, BOOL *stop) {
        port.center = CGPointMake(CGRectGetWidth(port.bounds) * 0.5f + self.portHorizontalSpacing,
                                    yPosition + CGRectGetHeight(port.bounds) * 0.5f);
        yPosition = CGRectGetMaxY(port.frame) + self.portVerticalSpacing;
        port.frame = CGRectIntegral(port.frame);
    }];
    
    yPosition = self.portStartYPosition;
    [self.outputPorts enumerateObjectsUsingBlock:^(DFPort *port, NSUInteger idx, BOOL *stop) {
        port.center = CGPointMake(CGRectGetWidth(self.bounds) - CGRectGetWidth(port.bounds) * 0.5f - self.portHorizontalSpacing,
                                  yPosition + CGRectGetHeight(port.bounds) * 0.5f);
        yPosition = CGRectGetMaxY(port.frame) + self.portVerticalSpacing;
        port.frame = CGRectIntegral(port.frame);
    }];
    self.gearView.center = CGPointMake(CGRectGetWidth(self.bounds)/2, CGRectGetHeight(self.bounds)/2);
}

- (void)destroyButtonPressed:(UIButton *)button
{
    [self.workspace removeNode:self];
}

- (BOOL)canConnectPort:(DFPort *)port toPort:(DFPort *)toPort
{
    return [self.operation canConnectPort:port.name ofOperation:port.node.operation toPort:toPort.name];
}

- (void)prepare_:(NSMutableSet *)preparedNodes
{
    [self cancel];
    [preparedNodes addObject:self];
    DFOperation *operation = self.operationCreationBlock();
    [self.inputPorts enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        DFPort *inputPort = obj;
        DFPort *connectedPort = inputPort.connectedPort;
        if (connectedPort) {
            DFNode *node = connectedPort.node;
            if (![preparedNodes containsObject:node]) {
                [node prepare_:preparedNodes];
            }
            DFOperation *dependentOperation = node.operation;
            if ([operation isKindOfClass:[DFReactiveOperation class]]) {
                DFReactiveOperation *reactiveOp = (DFReactiveOperation *)operation;
                [reactiveOp addReactiveDependency:dependentOperation withBindings:@{inputPort.name : connectedPort.name}];
            }
            else {
                [operation addDependency:dependentOperation withBindings:@{inputPort.name : connectedPort.name}];
            }
        }
    }];
    
    @weakify(operation);
    @weakify(self);
    AMBlockToken *stateObservationToken = nil;
    stateObservationToken = [operation addObserverForKeyPath:@keypath(operation.DF_state) task:^(id obj, NSDictionary *change) {
        @strongify(operation);
        @strongify(self);
        OperationState state = operation.DF_state;
        dispatch_async(dispatch_get_main_queue(), ^{
            if (state == OperationStateExecuting) {
                [self startGear];
            }
            else if (state == OperationStateDone) {
                [operation DF_safelyRemoveObserver:stateObservationToken];
                [self stopGearAfterDelay:0.2];
            }
        });
    }];
    self.stateObservationToken = stateObservationToken;
    self.operation = operation;
    [self startGear];
    [self.operation connectOutputToProperty:@keypath(self.result) ofObject:self onQueue:dispatch_get_main_queue()];
}

- (void)prepare
{
    NSMutableSet *preparedNodes = [NSMutableSet set];
    [self prepare_:preparedNodes];
}

- (void)startGear
{
    [self stopGear];
    
    UIImageView *imageView = [UIImageView new];
    imageView.backgroundColor = [UIColor clearColor];
    [imageView setImage:[UIImage imageNamed:@"gear"]];
    imageView.frame = CGRectMake(0, 0, 40, 40);
    imageView.center = self.center;
    [self addSubview:imageView];
    
    self.gearView = imageView;
    UIViewAnimationOptions options;
    options = (UIViewAnimationOptionRepeat | UIViewAnimationOptionCurveLinear |UIViewAnimationOptionBeginFromCurrentState);
    [UIView animateWithDuration:0.4
                          delay:0.0
                        options:options
                     animations:^{
                         imageView.transform = CGAffineTransformMakeRotation(M_PI);
                         
                     } completion:nil];
    
}

- (void)setResult:(id)result
{
    _result = result;
    [self.workspace displayResult:result ofNode:self];
}

- (void)stopGear
{
    [self.gearView.layer removeAllAnimations];
    [self.gearView removeFromSuperview];
    self.gearView = nil;
}

- (void)stopGearAfterDelay:(NSTimeInterval)delay
{
    @weakify(self);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        @strongify(self);
        [self stopGear];
    });
}

- (void)execute
{
    [self.operation startExecution];
}

- (void)cancel
{
    if (self.stateObservationToken) {
        [self.operation DF_safelyRemoveObserver:self.stateObservationToken];
        self.stateObservationToken = nil;
    }
    [self.operation removeOutputConnectionsForObject:self property:@keypath(self.result)];
    [self.operation cancel];
    self.operation = nil;
}

- (NSSet *)connectedNodes
{
    NSMutableSet *nodes = [NSMutableSet new];
    [self.inputPorts enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        DFPort *port = obj;
        DFNode *connectedNode = port.connectedPort.node;
        if (connectedNode) {
            [nodes addObject:connectedNode];
        }
    }];
    return nodes;
}

- (BOOL)isReactive
{
    return [self.operation isKindOfClass:[DFReactiveOperation class]];
}

- (Class)portType:(NSString *)port
{
    return [self.operation portType:port];
}

- (void)executeNode:(UIMenuItem *)item
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.workspace executeNode:self];
    });
}

- (void)makeNodeComposite:(UIMenuItem *)item
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.workspace makePatch:[NSString stringWithFormat:@"[ %@ ]", self.info.name] node:self];
    });
}

- (void)nodeTapped:(UITapGestureRecognizer *)recognizer
{
    if ([UIMenuController sharedMenuController].isMenuVisible) {
        [[UIMenuController sharedMenuController] setMenuVisible:NO animated:YES];
        return;
    }
    CGRect rect = CGRectZero;
    rect.origin = [recognizer locationInView:self];
    
    [[UIMenuController sharedMenuController] setTargetRect:rect inView:self];
    
   
    NSMutableArray *menuItems = [NSMutableArray array];
    
    UIMenuItem *executeItem = [[UIMenuItem alloc] initWithTitle:@"Execute" action:@selector(executeNode:)];
    [menuItems addObject:executeItem];
    
    UIMenuItem *compositeItem = [[UIMenuItem alloc] initWithTitle:@"Patch" action:@selector(makeNodeComposite:)];
    [menuItems addObject:compositeItem];
    
    [[UIMenuController sharedMenuController] setMenuItems:menuItems];
    [self becomeFirstResponder];
    [[UIMenuController sharedMenuController] update];
    [[UIMenuController sharedMenuController] setMenuVisible:YES animated:YES];
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

@end
