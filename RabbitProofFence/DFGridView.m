//
//  DFGridView.m
//  RabbitProofFence
//
//  Created by Sinha, Gyanendra on 11/15/14.
//  Copyright (c) 2014 Sinha, Gyanendra. All rights reserved.
//

#import "DFGridView.h"
#import "DFNode.h"
#import "DFPort.h"
#import "DFWorkspace.h"

#import "UIColor+FlatUI.h"
#import "EXTKeyPathCoding.h"

@interface DFGridView ()

@property (weak, nonatomic) CAShapeLayer *overlay;

@property (assign, nonatomic) CGPoint draggedObjectCenterOffset;

@property (strong, nonatomic) UIView *draggedObject;

@property (assign, nonatomic) CGPoint lastPanPosition;

@property (strong, nonatomic) NSMutableArray *nodes;

@property (weak, nonatomic) IBOutlet UIView *zoomableView;

@end

@implementation DFGridView

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        self.zoomableView.backgroundColor = [UIColor clearColor];
        UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                                               action:@selector(handlePanGesture:)];
        [self addGestureRecognizer:panGestureRecognizer];
        
        UIPinchGestureRecognizer *pinchGestureRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self
                                                                                                     action:@selector(handlePinchGesture:)];
        [self addGestureRecognizer:pinchGestureRecognizer];
        
        self.nodes = [NSMutableArray new];
    }
    return self;
}

- (CAShapeLayer *)overlay
{
    if (!_overlay) {
        CAShapeLayer *layer = [CAShapeLayer layer];
        self.overlay = layer;
        [self setupLinePropertiesForLayer:_overlay];
        [self.zoomableView.layer addSublayer:_overlay];
    }
    
    return _overlay;
}

- (void)setupLinePropertiesForLayer:(CAShapeLayer *)connectionLayer
{
    connectionLayer.frame = self.bounds;
    connectionLayer.zPosition = 2;
    connectionLayer.lineWidth = 2;
    connectionLayer.fillColor = UIColor.clearColor.CGColor;
    connectionLayer.strokeColor = [UIColor tealColor].CGColor;
    connectionLayer.allowsEdgeAntialiasing = YES;
    connectionLayer.lineCap = kCALineCapRound;
}

- (void)updateConnections
{
    [self.zoomableView.subviews enumerateObjectsUsingBlock:^(DFNode *node, NSUInteger idx, BOOL *stop) {
        if (![node isKindOfClass:DFNode.class]) {
            return;
        }
        
        [node.inputPorts enumerateObjectsUsingBlock:^(DFPort *inputPort, NSUInteger idx, BOOL *stop) {
            if (!inputPort.connectedPort) {
                return;
            }
            CAShapeLayer *layer = inputPort.connectionLayer;
            [self adjustConnectionLayer:layer fromPort:inputPort.connectedPort toPort:inputPort];
        }];
    }];
}

- (void)adjustConnectionLayer:(CAShapeLayer *)connectionLayer fromPort:(DFPort *)fromPort toPort:(DFPort *)toPort
{
    CGPoint startPoint = [connectionLayer convertPoint:[fromPort socketCenter] fromLayer:fromPort.layer];
    CGPoint targetPoint = [connectionLayer convertPoint:[toPort socketCenter] fromLayer:toPort.layer];
    connectionLayer.path = [self pathFromPoint:startPoint toPoint:targetPoint];
}

- (void)prepareConnectionLayerForPort:(DFPort *)port
{
    CAShapeLayer *connectionLayer = [CAShapeLayer layer];
    [self setupLinePropertiesForLayer:connectionLayer];
    [self.zoomableView.layer addSublayer:connectionLayer];
    port.connectionLayer = connectionLayer;
    if (port.node.isReactive) {
        connectionLayer.strokeColor = [UIColor redColor].CGColor;
    }
}

- (void)setOffset:(CGPoint)offset
{
    CGFloat offsetX = _offset.x - offset.x;
    CGFloat offsetY = _offset.y - offset.y;
    
    _offset = offset;
    [self.zoomableView.subviews enumerateObjectsUsingBlock:^(UIView *subview, NSUInteger idx, BOOL *stop) {
        CGPoint center = subview.center;
        center.x -= offsetX;
        center.y -= offsetY;
        subview.center = center;
    }];
    [self setNeedsDisplay];
}

- (void)handlePanGesture:(UIPanGestureRecognizer *)panGestureRecognizer
{
    CGPoint point = [panGestureRecognizer locationInView:self.zoomableView];
    switch (panGestureRecognizer.state) {
        case UIGestureRecognizerStateBegan: {
            __block BOOL found = NO;
            [self findObjectForPoint:point completion:^(DFPort *obj, CGPoint offset) {
                self.draggedObject = obj;
                self.draggedObjectCenterOffset = offset;
                if ([obj isKindOfClass:DFPort.class]) {
                    DFPort *port = obj;
                   [self markCompatiblePortsForOutputPort:port];
                }
                found = YES;
            }];
            if (!found) {
                self.lastPanPosition = point;
            }
        }
            break;
        case UIGestureRecognizerStateChanged: {
            if (self.draggedObject) {
                if ([self.draggedObject isKindOfClass:DFPort.class]) {
                    CGPoint socketCenter = [self.zoomableView convertPoint:[(DFPort *)self.draggedObject socketCenter]
                                                                  fromView:self.draggedObject];
                    
                    self.overlay.path = [self pathFromPoint:socketCenter toPoint:[self convertPoint:point
                                                                                           fromView:panGestureRecognizer.view]];
                    [self updateConnections];
                    return;
                }
                self.draggedObject.center = CGPointMake(self.draggedObjectCenterOffset.x + point.x, self.draggedObjectCenterOffset.y + point.y);
                [self updateConnections];
            }
            else {
                CGFloat offsetX = self.lastPanPosition.x - point.x;
                CGFloat offsetY = self.lastPanPosition.y - point.y;
                self.lastPanPosition = point;
                
                CGPoint offset = self.offset;
                offset.x -= offsetX;
                offset.y -= offsetY;
                self.offset = offset;
                [self updateConnections];
            }
        }
            break;
            
        case UIGestureRecognizerStateEnded: {
            [self findObjectForPoint:point completion:^(DFPort *inputPort, CGPoint offset) {
                if ([self.draggedObject isKindOfClass:DFPort.class] && [inputPort isKindOfClass:DFPort.class]) {
                    BOOL canConnect = [(DFPort *)self.draggedObject canConnectToPort:inputPort];
                    if (canConnect) {
                        if (inputPort.connectedPort) {
                            [self.workspace breakConnectionFromPort:inputPort.connectedPort toPort:inputPort];
                        }
                        [self prepareConnectionLayerForPort:inputPort];
                        [(DFPort *)self.draggedObject connectToPort:inputPort];
                    }
                }
            }];
        }
        case UIGestureRecognizerStateCancelled: {
            self.draggedObject = nil;
            self.draggedObjectCenterOffset = CGPointZero;
            self.overlay.path = nil;
            [self updateConnections];
            [self markCompatiblePortsForOutputPort:nil];
        }
            break;
            
        default:
            break;
    }
}

- (void)markCompatiblePortsForOutputPort:(DFPort *)port
{
    [self.nodes enumerateObjectsUsingBlock:^(DFNode *node, NSUInteger idx, BOOL *stop) {
        if (node == port.node) {
            return;
        }
        [node.inputPorts enumerateObjectsUsingBlock:^(DFPort *inputPort, NSUInteger idx, BOOL *stop) {
            [inputPort setCompatible:port ? [port canConnectToPort:inputPort] : YES];
        }];
    }];
}

- (void)handlePinchGesture:(UIPinchGestureRecognizer *)pinchGestureRecognizer
{
    CGFloat scale = pinchGestureRecognizer.scale;
    pinchGestureRecognizer.scale = 1;
    self.zoomableView.transform = CGAffineTransformScale(self.zoomableView.transform, scale, scale);
}

- (void)findObjectForPoint:(CGPoint)point completion:(void (^)(id obj, CGPoint offset))completion
{
    [[self.nodes copy] enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(DFNode *node, NSUInteger idx, BOOL *stop) {
        CGPoint localPoint = [node.layer convertPoint:point fromLayer:self.zoomableView.layer];
        DFPort *port = [node portForTouchPoint:localPoint];
        if (port) {
            completion(port, CGPointMake(port.center.x - point.x, port.center.y - point.y));
            *stop = YES;
            return;
        }
        
        if ([node canDragWithPoint:localPoint]) {
            completion(node, CGPointMake(node.center.x - point.x, node.center.y - point.y));
            [self.nodes removeObject:node];
            [self.nodes addObject:node];
            [self.zoomableView bringSubviewToFront:node];
            *stop = YES;
        }
    }];
}

- (void)animateValueFlowFromPort:(DFPort *)fromPort toPort:(DFPort *)toPort
{
    if (!toPort.connectionLayer) {
        return;
    }
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path addArcWithCenter:CGPointZero
                    radius:10
                startAngle:0.0
                  endAngle:M_PI * 2.0
                 clockwise:YES];
    
    CAShapeLayer *shapeLayer = [CAShapeLayer layer];
    shapeLayer.fillColor = toPort.connectionLayer.strokeColor;
    shapeLayer.path = [path CGPath];
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    [toPort.connectionLayer addSublayer:shapeLayer];
    [CATransaction commit];
    [CATransaction begin];
    [CATransaction setCompletionBlock:^{
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        [shapeLayer removeFromSuperlayer];
        [CATransaction commit];
    }];
    [CATransaction setAnimationDuration:0.3];
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@keypath(shapeLayer.position)];
    animation.path = toPort.connectionLayer.path;
    animation.calculationMode = @"paced";
    [shapeLayer addAnimation:animation forKey:@"flow"];
    [CATransaction commit];
}


- (CGPathRef)pathFromPoint:(CGPoint)startPoint toPoint:(CGPoint)endPoint
{
    //! http://stackoverflow.com/questions/8024736/how-to-compute-the-control-points-for-a-smooth-path-given-a-set-of-points
    CGMutablePathRef curvedPath = CGPathCreateMutable();
    const int TOTAL_POINTS = 3;
    int horizontalWiggle = 20;
    
    int stepChangeX = (int)((endPoint.x - startPoint.x) / TOTAL_POINTS);
    int stepChangeY = (int)((endPoint.y - startPoint.y) / TOTAL_POINTS);
    
    for (int i = 0; i < TOTAL_POINTS; i++) {
        int startX = (int)(startPoint.x + i * stepChangeX);
        int startY = (int)(startPoint.y + i * stepChangeY);
        
        int endX = (int)(startPoint.x + (i + 1) * stepChangeX);
        int endY = (int)(startPoint.y + (i + 1) * stepChangeY);
        
        int cpX1 = (int)(startPoint.x + (i + 0.25) * stepChangeX);
        if ((i + 1) % 2) {
            cpX1 -= horizontalWiggle;
        } else {
            cpX1 += horizontalWiggle;
        }
        int cpY1 = (int)(startPoint.y + (i + 0.25) * stepChangeY);
        
        int cpX2 = (int)(startPoint.x + (i + 0.75) * stepChangeX);
        if ((i + 1) % 2) {
            cpX2 -= horizontalWiggle;
        } else {
            cpX2 += horizontalWiggle;
        }
        int cpY2 = (int)(startPoint.y + (i + 0.75) * stepChangeY);
        
        CGPathMoveToPoint(curvedPath, NULL, startX, startY);
        CGPathAddCurveToPoint(curvedPath, NULL, cpX1, cpY1, cpX2, cpY2, endX, endY);
    }
    
    return curvedPath;
}

- (void)addNode:(DFNode *)node
{
    [self.nodes addObject:node];
    [self.zoomableView addSubview:node];
}

- (void)removeNode:(DFNode *)node
{
    [self.nodes removeObject:node];
    [node removeFromSuperview];
}

- (void)clearConnectionLayerForPort:(DFPort *)port
{
    [port.connectionLayer removeFromSuperlayer];
}

@end
