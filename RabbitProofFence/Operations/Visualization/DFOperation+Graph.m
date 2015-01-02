//
//  DFOperation+Visual.m
//  RabbitProofFence
//
//  Created by Sinha, Gyanendra on 11/7/14.
//  Copyright (c) 2014 Sinha, Gyanendra. All rights reserved.
//

#import "DFOperation+Graph.h"
#import "DFOperation_SubclassingHooks.h"
#import "DFReactiveOperation.h"
#import "DFIdentityOperation.h"
#import "DFPort.h"
#import "DFNode.h"
#import "DFValueNode.h"

#import "NSArray+Utility.h"
#import "UIView+DebugObject.h"

@implementation DFOperation (Graph)

- (NSArray *)inputPortsInfo
{
    return [self.inputPorts map:^id(id obj, NSUInteger idx) {
        NSString *name = obj;
        DFPortInfo *info = [DFPortInfo new];
        info.name = name;
        info.dataType = [NSObject class];
        info.portType = DFPortTypeInput;
        return info;
    }];
}

- (NSArray *)outputPortsInfo
{
    DFPortInfo *info = [DFPortInfo new];
    info.name = @keypath(self.output);
    info.dataType = [NSObject class];
    info.portType = DFPortTypeOutput;
    return @[info];
}

- (DFNodeInfo *)info
{
    DFNodeInfo *info = [DFNodeInfo new];
    info.name = self.name.length > 0 ? self.name : NSStringFromClass([self class]);
    info.nodeColor = [self isKindOfClass:[DFReactiveOperation class]] ? [UIColor redColor] : [UIColor blueColor];
    info.inputPorts = [self inputPortsInfo];
    info.outputPorts = [self outputPortsInfo];
    return info;
}

- (DFNode *)visualRepresentation
{
    if ([self isKindOfClass:[DFIdentityOperation class]]) {
        return [DFValueNode nodeWithInfo:[self info]];
    }
    else {
        return [DFNode nodeWithInfo:[self info]];
    }
}

NS_INLINE NSUInteger levelForOperation(DFOperation *operation, NSArray *levels)
{
    __block NSUInteger level = NSNotFound;
    [levels enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSMutableSet *operations = obj;
        if ([operations containsObject:operation]) {
            level = idx;
            *stop = YES;
        };
    }];
    return level;
}

NS_INLINE CGFloat yHeight(DFNode *firstNode, DFNode *secondNode)
{
    return CGRectGetMaxY([firstNode frame]) - CGRectGetMinY([secondNode frame]);
}

NS_INLINE CGFloat levelHeight(NSArray *levelNodes)
{
    NSUInteger n = levelNodes.count;
    CGFloat levelHeight = 0;
    if (n > 1) {
        levelHeight = (n % 2) == 1 ? yHeight(levelNodes[n - 1], levelNodes[n - 2]) : yHeight(levelNodes[n - 2], levelNodes[n - 1]);
    }
    else if (n == 1) {
        levelHeight = [levelNodes[0] frame].size.height;
    }
    return levelHeight;
}

NS_INLINE CGFloat minY(NSArray *levelNodes)
{
    NSUInteger n = levelNodes.count;
    CGFloat levelHeight = 0;
    if (n > 1) {
        levelHeight = (n % 2) == 0 ? CGRectGetMinY([levelNodes[n - 1] frame]) : CGRectGetMinY([levelNodes[n - 2] frame]);
    }
    else if (n == 1) {
        levelHeight = CGRectGetMinY([levelNodes[0] frame]);
    }
    return levelHeight;
}

NS_INLINE CGFloat maxWidth(NSArray *nodes)
{
    __block CGFloat width = 0;
    [nodes enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        width = MAX(width, [obj bounds].size.width);
    }];
    return width;
}

NS_INLINE DFNode *nodeForOperation(DFOperation *operation, NSArray *nodes)
{
    __block DFNode *result = nil;
    [nodes enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSArray *levelNodes = obj;
        [levelNodes enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            DFNode *node = obj;
            if (node.operation == operation) {
                result = node;
                *stop = YES;
            }
        }];
        if (result) {
            *stop = YES;
        }
    }];
    return result;
}

- (void)walkDependencyGraph:(NSMutableArray *)levels level:(NSUInteger)level
{
    if (level >= levels.count) {
        [levels addObject:[NSMutableSet set]];
    }
    NSUInteger index = levelForOperation(self, levels);
    if (index != NSNotFound) {
        if (level > index) {
            NSMutableSet *operations = levels[index];
            [operations removeObject:self];
        }
        else {
            level = index;
        }
    }
    NSMutableSet *operations = levels[level];
    [operations addObject:self];
    [self.connectedOperations enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        DFOperation *operation = obj;
        [operation walkDependencyGraph:levels level:(level + 1)];
    }];
}

- (CGPathRef)pathFromPoint:(CGPoint)startPoint toPoint:(CGPoint)endPoint
{
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

- (void)setupLinePropertiesForLayer:(CAShapeLayer *)connectionLayer view:(UIView *)view
{
    connectionLayer.frame = view.layer.bounds;
    connectionLayer.zPosition = 2;
    connectionLayer.lineWidth = 2;
    connectionLayer.fillColor = UIColor.clearColor.CGColor;
    connectionLayer.strokeColor = [UIColor blueColor].CGColor;
    connectionLayer.allowsEdgeAntialiasing = YES;
    connectionLayer.lineCap = kCALineCapRound;
}

- (CAShapeLayer *)connectionLayerForContainerView:(UIView *)view
{
    CAShapeLayer *connectionLayer = [CAShapeLayer layer];
    [self setupLinePropertiesForLayer:connectionLayer view:view];
    [view.layer addSublayer:connectionLayer];
    return connectionLayer;
}

- (void)connect:(CAShapeLayer *)connectionLayer port:(DFPort *)port toPort:(DFPort *)toPort
{
    CGPoint startPoint = [connectionLayer convertPoint:[port socketCenter] fromLayer:port.layer];
    CGPoint targetPoint = [connectionLayer convertPoint:[toPort socketCenter] fromLayer:toPort.layer];
    connectionLayer.path = [self pathFromPoint:startPoint toPoint:targetPoint];
}

- (void)connect:(CAShapeLayer *)connectionLayer node:(DFNode *)node toNode:(DFNode *)toNode
{
    CGPoint startPoint = [connectionLayer convertPoint:[node center] fromLayer:connectionLayer.superlayer];
    CGPoint targetPoint = [connectionLayer convertPoint:[toNode center] fromLayer:connectionLayer.superlayer];
    connectionLayer.path = [self pathFromPoint:startPoint toPoint:targetPoint];
}

- (void)groundPort:(DFPort *)port
{
    CGPoint center = port.socketCenter;
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path addArcWithCenter:center
                    radius:10
                startAngle:0.0
                  endAngle:M_PI * 2.0
                 clockwise:YES];
    
    CAShapeLayer *shapeLayer = [CAShapeLayer layer];
    shapeLayer.fillColor = [[UIColor grayColor] CGColor];
    shapeLayer.path = [path CGPath];
    [port.layer addSublayer:shapeLayer];
}

- (void)connectPorts:(NSArray *)nodes view:(UIView *)view
{
    [nodes enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSArray *levelNodes = obj;
        [levelNodes enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            DFNode *node = obj;
            DFOperation *operation = node.operation;
            [operation.connectedOperations enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                DFOperation *dependentOperation = obj;
                NSDictionary *bindings = [operation bindingsForOperation:dependentOperation];
                DFNode *dependentNode = nodeForOperation(dependentOperation, nodes);
                // port bindings
                if (bindings.count > 0) {
                    [bindings enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                        NSString *inPortName = key;
                        NSString *outPortName = obj;
                        DFPort *inPort = [node portForName:inPortName];
                        DFPort *outPort = [dependentNode portForName:outPortName];
                        CAShapeLayer *connectionLayer = [self connectionLayerForContainerView:view];
                        if ([operation isKindOfClass:[DFReactiveOperation class]]) {
                            DFReactiveOperation *reactiveOperation = (DFReactiveOperation *)operation;
                            if ([reactiveOperation isBindingReactive:@{inPortName : outPortName}]) {
                                connectionLayer.strokeColor = [UIColor redColor].CGColor;
                            }
                        }
                        [self connect:connectionLayer port:outPort toPort:inPort];
                    }];
                }
                else {
                    // dependency but no binding
                    CAShapeLayer *connectionLayer = [self connectionLayerForContainerView:view];
                    [self connect:connectionLayer node:dependentNode toNode:node];
                }
            }];
            NSArray *exludedPorts = [operation.execludedPorts allObjects];
            [exludedPorts enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                NSString *portName = obj;
                DFPort *port = [node portForName:portName];
                [self groundPort:port];
            }];
        }];
    }];
}

- (NSArray *)sortedOperations:(NSArray *)operations
{
   return [operations sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        DFOperation *operation1 = obj1;
        DFOperation *operation2 = obj2;
       
        return [@(operation1.dependencies.count) compare:@(operation2.dependencies.count)];
    }];
}

- (void)layoutNodesInView:(UIView *)view nodeSeparation:(CGPoint)separation
{
    NSMutableArray *levels = [NSMutableArray array];
    [self walkDependencyGraph:levels level:0];
    NSMutableArray *nodes = [NSMutableArray arrayWithCapacity:levels.count];
    CGFloat xSeparation = separation.x;
    CGFloat ySeparation = separation.y;
    __block CGFloat maxLevelHeight = 0;
    [levels enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSMutableSet *operations = obj;
        //sort it by dependency count
        NSArray *sortedOperations = [[operations allObjects] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            DFOperation *operation1 = obj1;
            DFOperation *operation2 = obj2;
            return [@(operation1.dependencies.count) compare:@(operation2.dependencies.count)];
        }];
        NSMutableArray *levelNodes = [NSMutableArray arrayWithCapacity:sortedOperations.count];
        [sortedOperations enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            DFOperation *operation = obj;
            DFNode *node = [operation visualRepresentation];
            node.operation = operation;
            CGSize size = [node systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
            node.frame = CGRectMake(0, 0, size.width, size.height);
            CGFloat y = 0;
            if (idx > 0) {
                NSUInteger normalizedIndex = (idx > 1) ? (idx - 2) :  0;
                y = (idx %2 == 0) ? CGRectGetMaxY([levelNodes[normalizedIndex] frame]) + ySeparation + size.width/2 :
                CGRectGetMinY([levelNodes[normalizedIndex] frame]) - ySeparation - size.width/2;
            }
            else {
                y = 0;
            }
            node.center = (CGPoint){0.0, y};
            [node setNeedsLayout];
            [node layoutIfNeeded];
            [levelNodes addObject:node];
        }];
        [nodes addObject:levelNodes];
        CGFloat height = levelHeight(levelNodes);
        maxLevelHeight = MAX(maxLevelHeight, height);
    }];
    
    __block CGFloat x = 0;
    __block CGRect rect = CGRectZero;
    [nodes enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSArray *levelNodes = obj;
        CGFloat width = maxWidth(levelNodes);
        CGFloat xDisplacement = x + width/2.0;
        CGFloat yDisplacement = - minY(levelNodes) + (maxLevelHeight - levelHeight(levelNodes))/2.0;
        [levelNodes enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            DFNode *node = obj;
            CGRect frame = node.frame;
            frame.origin = (CGPoint){frame.origin.x + xDisplacement, frame.origin.y + yDisplacement};
            node.frame = frame;
            rect = CGRectUnion(rect, node.frame);
            [view addSubview:node];
        }];
        x += (width + xSeparation);
    }];
    view.frame = rect;
    [view setNeedsLayout];
    [view layoutIfNeeded];
    [self connectPorts:nodes view:view];
}

- (id)debugQuickLookObject
{
    UIView *ws = [UIView new];
    UIView *contentView = [UIView new];
    [self layoutNodesInView:contentView nodeSeparation:(CGPoint){80, 40}];
    CGFloat inset = 40;
    CGRect rect = CGRectMake(0, 0, contentView.bounds.size.width + inset, contentView.bounds.size.height + inset);
    ws.bounds = rect;
    [ws addSubview:contentView];
    contentView.center = (CGPoint){CGRectGetMidX(rect), CGRectGetMidY(rect)};
    return [ws debugQuickLookObject];
}


@end
