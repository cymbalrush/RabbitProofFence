//
//  DFWorkSpace.m
//  RabbitProofFence
//
//  Created by Sinha, Gyanendra on 11/7/14.
//  Copyright (c) 2014 Sinha, Gyanendra. All rights reserved.
//

#import "DFWorkspace.h"
#import "DFGridView.h"
#import "DFNode.h"
#import "Operations.h"
#import "DFPort.h"

#import "UIColor+Crayola.h"
#import "EXTKeyPathCoding.h"
#import "DFOperation_SubclassingHooks.h"

NSString * const DFWorkSpaceExceptionOperationAlreadyRegistered = @"OperationAlreadyRegistered";

@interface DFWorkspace ()

@property (weak, nonatomic) IBOutlet UIView *previewView;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (weak, nonatomic) IBOutlet DFGridView *gridView;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *leftViewTrailingConstraint;

@property (strong, nonatomic) NSMutableArray *nodes;

@property (strong, nonatomic) NSDictionary *creationBlocks;

@property (strong, nonatomic) UITextView *textView;

@property (weak, nonatomic) DFNode *executingNode;


@end

@implementation DFWorkspace

+ (instancetype)workspaceWithBounds:(CGRect)bounds
{
    UINib *nib = [UINib nibWithNibName:NSStringFromClass(self.class) bundle:[NSBundle bundleForClass:self]];
    DFWorkspace *workspace = [[nib instantiateWithOwner:nil options:nil] firstObject];
    workspace.bounds = bounds;
    return workspace;
}

+ (NSMutableDictionary *)creationBlocks
{
    static NSMutableDictionary *mapping = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        mapping = [NSMutableDictionary new];
    });
    return mapping;
}

+ (NSMutableArray *)activeWorkSpaces_
{
    static NSMutableArray *workSpaces = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        workSpaces = [NSMutableArray new];
    });
    return workSpaces;
}

+ (NSArray *)activeWorkSpaces
{
    return [[self activeWorkSpaces_] copy];
}

+ (void)reloadActiveWorkSpaces
{
    [[self activeWorkSpaces] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        DFWorkspace *ws = obj;
        [ws reload];
    }];
}

+ (void)registerOpertaionCreationBlock:(DFOperation *(^)(void))creationBlock forName:(NSString *)name
{
    if ([self creationBlocks][name]) {
        NSString *reason = [NSString stringWithFormat:@"Block already registered for name"];
        @throw [NSException exceptionWithName:DFWorkSpaceExceptionOperationAlreadyRegistered reason:reason userInfo:nil];
    }
    else {
        [self creationBlocks][name] = [creationBlock copy];
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(reloadActiveWorkSpaces) object:nil];
        [self performSelector:@selector(reloadActiveWorkSpaces) withObject:nil afterDelay:0.0];
    }
}

+ (void)removeOperationCreationBlockForName:(NSString *)name
{
    if ([self creationBlocks][name]) {
        [[self creationBlocks] removeObjectForKey:name];
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(reloadActiveWorkSpaces) object:nil];
        [self performSelector:@selector(reloadActiveWorkSpaces) withObject:nil afterDelay:0.0];
    }
}


- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.gridView.workspace = self;
    NSArray *constraints = nil;
    NSString *constraintDesc = nil;
    
    UITextView *textView = [UITextView new];
    [textView setTranslatesAutoresizingMaskIntoConstraints:NO];
    textView.textColor = [UIColor whiteColor];
    textView.backgroundColor = [UIColor clearColor];
    
    [self.previewView addSubview:textView];
    
    constraintDesc = @"H:|-0-[textView]-0-|";
    constraints = [NSLayoutConstraint constraintsWithVisualFormat:constraintDesc
                                                          options:NSLayoutFormatDirectionLeadingToTrailing
                                                          metrics:nil
                                                            views:NSDictionaryOfVariableBindings(textView)];
    
    [self.previewView addConstraints:constraints];
    
    constraintDesc = @"V:|-0-[textView]-0-|";
    constraints = [NSLayoutConstraint constraintsWithVisualFormat:constraintDesc
                                                          options:NSLayoutFormatDirectionLeadingToTrailing
                                                          metrics:nil
                                                            views:NSDictionaryOfVariableBindings(textView)];
    
    
    [self.previewView addConstraints:constraints];
    self.textView = textView;
    
    UINib *nib = [UINib nibWithNibName:@"DFWorkspaceBlockCell" bundle:[NSBundle bundleForClass:self.class]];
    [self.tableView registerNib:nib forCellReuseIdentifier:@"DefaultCell"];
    
    self.previewView.layer.borderWidth = 1.0;
    self.previewView.layer.borderColor = [[UIColor whiteColor] CGColor];
    self.previewView.backgroundColor = [UIColor crayolaPacificBlueColor];
    
    self.gridView.backgroundColor = [UIColor crayolaPacificBlueColor];
    
    self.tableView.layer.borderWidth = 1.0;
    self.tableView.layer.borderColor = [[UIColor whiteColor] CGColor];
    self.tableView.backgroundColor = [UIColor crayolaPacificBlueColor];
}

- (void)toggleLeftPane
{
    CGFloat multiplier = self.leftViewTrailingConstraint.multiplier;
    multiplier = (multiplier > 1) ? 1 : (1.4);
    
    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:self.leftViewTrailingConstraint.firstItem
                                                                  attribute:self.leftViewTrailingConstraint.firstAttribute
                                                                  relatedBy:self.leftViewTrailingConstraint.relation
                                                                     toItem:self.leftViewTrailingConstraint.secondItem
                                                                  attribute:self.leftViewTrailingConstraint.secondAttribute
                                                                 multiplier:multiplier
                                                                   constant:self.leftViewTrailingConstraint.constant];
    [self removeConstraint:self.leftViewTrailingConstraint];
    [self addConstraint:constraint];
    self.leftViewTrailingConstraint = constraint;
    [self setNeedsLayout];
    [UIView animateWithDuration:0.3 animations:^{[self layoutIfNeeded];}];
}

- (void)setup
{
    [[[self class] activeWorkSpaces_] addObject:self];
    self.nodes = [NSMutableArray new];
}

- (void)reload
{
    self.creationBlocks = [[[self class] creationBlocks] copy];
    [self.tableView reloadData];
}

- (void)pressedPort:(DFPort *)port
{
    if ([port isKindOfClass:DFPort.class] && port.portType == DFPortTypeInput && port.connectedPort) {
        [self breakConnectionFromPort:port.connectedPort toPort:port];
    }
}

- (void)breakConnectionFromPort:(DFPort *)outputPort toPort:(DFPort *)inputPort
{
    [self.gridView clearConnectionLayerForPort:outputPort];
    [outputPort removeConnectionToPort:inputPort];
}

- (void)addNode:(DFNode *)node
{
    CGSize size = [node systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    node.frame = CGRectMake(0, 0, size.width, size.height);
    node.center = self.center;
    node.transform = CGAffineTransformMakeScale(0.7, 0.7);
    node.workspace = self;
    [self.nodes addObject:node];
    //add node to gridview
    [self.gridView addNode:node];
    
    [UIView animateWithDuration:0.3
                          delay:0.0
         usingSpringWithDamping:0.6
          initialSpringVelocity:0.0
                        options:(UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction)
                     animations:^{
                         node.transform = CGAffineTransformIdentity;
                     } completion:^(BOOL finished) {
                         
                     }];
}

- (void)removeNode:(DFNode *)node animate:(BOOL)animate
{
    if ([self.nodes indexOfObject:node] == NSNotFound) {
        return;
    }
    [self.nodes removeObject:node];
    [node reset];
    if (animate) {
        [UIView animateWithDuration:0.3
                              delay:0.0
             usingSpringWithDamping:0.6
              initialSpringVelocity:0.0
                            options:(UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction)
                         animations:^{
                             node.transform = CGAffineTransformMakeScale(0.2, 0.2);
                             node.alpha = 0.0;
                         } completion:^(BOOL finished) {
                             [self.gridView removeNode:node];
                         }];
    }
    else {
        [self.gridView removeNode:node];
    }
    
}

- (void)removeNode:(DFNode *)node
{
    [self removeNode:node animate:YES];
}

- (void)removeNodeRecursively:(DFNode *)node
{
    [[node connectedNodes] enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        DFNode *connectedNode = obj;
        [self removeNodeRecursively:connectedNode];
    }];
    [self removeNode:node];
}

- (void)executeNode:(DFNode *)node
{
    self.textView.text = @"";
    self.executingNode = node;
    [node prepare];
    [node execute];
}

- (void)makePatch:(NSString *)name node:(DFNode *)node
{
    [node prepare];
    CGPoint center = node.center;
    DFOperation *operation = node.operation;
    DFParallelOperation *patch = [DFParallelOperation operationFromOperation:operation];
    [patch setName:name];
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    [self removeNodeRecursively:node];
    [CATransaction commit];
    DFNode *patchNode = [patch visualRepresentation];
    patchNode.operation = patch;
    [self addNode:patchNode];
    patchNode.center = center;
    patchNode.operationCreationBlock = ^(void) {
        return [patch DF_clone];
    };
}

- (void)printResult:(NSString *)text
{
    NSString *description = text ? [text description] : @"";
    NSMutableParagraphStyle *paragrapStyle = NSMutableParagraphStyle.new;
    paragrapStyle.alignment  = NSTextAlignmentCenter;
    
    NSMutableAttributedString *attributedString = [NSMutableAttributedString.alloc initWithString:description];
    [attributedString addAttribute:NSParagraphStyleAttributeName value:paragrapStyle range:NSMakeRange(0, description.length)];
    
    UIFont *font = [UIFont fontWithName:@"HelveticaNeue-Light" size:30];
    [attributedString addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, description.length)];
    
    [UIView transitionWithView:self.textView
                      duration:0.2
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
                        self.textView.attributedText = attributedString;
                    }
                    completion:nil];
    

}

- (void)displayResult:(id)result ofNode:(DFNode *)node
{
    DFOperation *operation = nil;
    if (node == self.executingNode) {
        [self printResult:result];
        return;
    }
    DFPort *port = [node portForName:@keypath(operation.output)];
    [CATransaction begin];
    [port.connections enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        [self.gridView animateValueFlowFromPort:port toPort:obj];
    }];
    [CATransaction commit];
}

#pragma mark - UITableView DS

NS_INLINE NSArray *sortedKeys(NSDictionary *dictionary)
{
    return [[dictionary allKeys] sortedArrayUsingSelector:@selector(compare:)];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.creationBlocks allKeys].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DefaultCell" forIndexPath:indexPath];
    cell.contentView.backgroundColor = [UIColor crayolaPacificBlueColor];
    cell.textLabel.text = sortedKeys(self.creationBlocks)[indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *key = sortedKeys(self.creationBlocks)[indexPath.row];
    DFOperation *(^creationBlock)(void) = self.creationBlocks[key];
    DFOperation *operation = creationBlock();
    DFNode *node = [operation visualRepresentation];
    node.operation = operation;
    node.operationCreationBlock = creationBlock;
    [self addNode:node];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
