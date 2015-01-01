//
//  ViewController.m
//  RabbitProofFence
//
//  Created by Sinha, Gyanendra on 11/6/14.
//  Copyright (c) 2014 Sinha, Gyanendra. All rights reserved.
//

#import "ViewController.h"
#import "Operations.h"
#import "DFOperation+Graph.h"
#import "DFWorkspace.h"
#import "DFVoidObject.h"

@interface ViewController ()

@property (strong, nonatomic) DFBackgroundOperation *op;

@end

@implementation ViewController

+ (CGAffineTransform)translatedAndScaledTransformUsingViewRect:(CGRect)viewRect fromRect:(CGRect)fromRect {
    
    CGSize scales = CGSizeMake(viewRect.size.width/fromRect.size.width, viewRect.size.height/fromRect.size.height);
    CGPoint offset = CGPointMake(CGRectGetMidX(viewRect) - CGRectGetMidX(fromRect), CGRectGetMidY(viewRect) - CGRectGetMidY(fromRect));
    return CGAffineTransformMake(scales.width, 0, 0, scales.height, offset.x, offset.y);
    
}


- (void)viewDidLoad {
    [super viewDidLoad];
  
    [DFWorkspace registerOpertaionCreationBlock:^DFOperation *{
        DFOperation *addOperation = OperationFromBlock([DFBackgroundOperation class], ^(NSNumber *x1, NSNumber *x2) {
            return @([x1 intValue] + [x2 intValue]);
            
        });
        NameOperation(addOperation);
        return addOperation;
    } forName:@"Add"];
    
    [DFWorkspace registerOpertaionCreationBlock:^DFOperation *{
        DFOperation *subOperation = OperationFromBlock([DFBackgroundOperation class], ^(NSNumber *x1, NSNumber *x2) {
            return @([x1 intValue] - [x2 intValue]) ;
            
        });
        NameOperation(subOperation);
        return subOperation;
    } forName:@"Subtract"];
    
    
    [DFWorkspace registerOpertaionCreationBlock:^DFOperation *{
        DFIdentityOperation *value = [DFIdentityOperation new];
        NameOperation(value);
        return value;
    } forName:@"TextInput"];
    
    
    [DFWorkspace registerOpertaionCreationBlock:^DFOperation *{
        DFOperation *splitter = OperationFromBlock([DFBackgroundOperation class], ^(NSString *text, NSString *separator) {
            return [text componentsSeparatedByString:separator] ;
        });
        [splitter setValue:@"," forKey:@"separator"];
        NameOperation(splitter);
        return splitter;
    } forName:@"TextSplitter"];
    
    [DFWorkspace registerOpertaionCreationBlock:^DFOperation *{
        DFOperation *intConverter = OperationFromBlock([DFBackgroundOperation class], ^(NSString *text) {
            return @([text integerValue]) ;
        });
        NameOperation(intConverter);
        return intConverter;
    } forName:@"IntegerConverter"];
    
    [DFWorkspace registerOpertaionCreationBlock:^DFOperation *{
        ArrayGenerator *seq = [ArrayGenerator generator];
        NameOperation(seq);
        return seq;
    } forName:@"ArraySequence"];
    
    [DFWorkspace registerOpertaionCreationBlock:^DFOperation *{
        DFAggregatorOperation *agg = [DFAggregatorOperation new];
        NameOperation(agg);
        return agg;
    } forName:@"Aggregator"];
    
    [DFWorkspace registerOpertaionCreationBlock:^DFOperation *{
        DFAnyOperation *any = [DFAnyOperation anyOperation:@[@"x1", @"x2"]];
        NameOperation(any);
        return any;
    } forName:@"Any"];
    
    [DFWorkspace registerOpertaionCreationBlock:^DFOperation *{
        DFAndOperation *and = [DFAndOperation andOperation:@[@"x1", @"x2"]];
        NameOperation(and);
        return and;
    } forName:@"And"];
   
    [DFWorkspace registerOpertaionCreationBlock:^DFOperation *{
        DFNetworkOperation *network = [DFNetworkOperation new];
        NameOperation(network);
        return network;
    } forName:@"Network"];
    
    [DFWorkspace registerOpertaionCreationBlock:^DFOperation *{
        DFOperation *urlConverter = OperationFromBlock([DFBackgroundOperation class], ^(NSString *text) {
            return [NSURLRequest requestWithURL:[NSURL URLWithString:text]] ;
        });
        NameOperation(urlConverter);
        return urlConverter;
    } forName:@"URLConverter"];
    
    [DFWorkspace registerOpertaionCreationBlock:^DFOperation *{
        DFOperation *arraySelector = OperationFromBlock([DFBackgroundOperation class], ^(NSArray *array, NSNumber *index) {
            NSUInteger idx = [index integerValue];
            return array[idx] ;
        });
        NameOperation(arraySelector);
        return arraySelector;
    } forName:@"ArraySelector"];
    
    [DFWorkspace registerOpertaionCreationBlock:^DFOperation *{
        DFOperation *flattenInput = [DFFlattenOperation new];
        NameOperation(flattenInput);
        return flattenInput;
    } forName:@"Flatten"];
    
    [DFWorkspace registerOpertaionCreationBlock:^DFOperation *{
        DFDelayOperation *delay = [DFDelayOperation new];
        NameOperation(delay);
        return delay;
    } forName:@"Delay"];
    
    [DFWorkspace registerOpertaionCreationBlock:^DFOperation *{
        DFGenerator *forSeq =  OperationFromBlock([DFGenerator class], ^(NSNumber *i, NSNumber *j, NSNumber *inc, DFGenerator *selfRef) {
            NSInteger value = [i integerValue];
            if (!isVoid(selfRef.output)) {
                value = [selfRef.output integerValue] + [inc integerValue];
            }
            if (value >= [j integerValue]) {
                [selfRef stop];
            }
            return @(value);
            
        });
        [forSeq setValue:@(1) forKey:@"inc"];

        NameOperation(forSeq);
        return forSeq;
    } forName:@"For"];
    
    DFWorkspace *ws = [DFWorkspace workspaceWithBounds:self.view.bounds];

    [self.view addSubview:ws];
    ws.center = (CGPoint){CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds)};
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(BOOL)shouldAutorotate
{
    return YES;
}

-(NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskLandscape;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationLandscapeRight;
}


@end
