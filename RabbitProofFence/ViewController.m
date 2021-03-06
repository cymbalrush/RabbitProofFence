//
//  ViewController.m
//  RabbitProofFence
//
//  Created by Sinha, Gyanendra on 11/6/14.
//  Copyright (c) 2014 Sinha, Gyanendra. All rights reserved.
//

#import "ViewController.h"
#import "Operations.h"

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
  
    [DFWorkspace registerOperationCreationBlock:^DFOperation *{
        DFOperation *add = OperationFromBlock([DFBackgroundOperation class], ^(NSNumber *x1, NSNumber *x2) {
            return @([x1 intValue] + [x2 intValue]);
        });
        NameOperation(add);
        return add;
    } forName:@"Add"];
    
    [DFWorkspace registerOperationCreationBlock:^DFOperation *{
        DFOperation *sub = OperationFromBlock([DFBackgroundOperation class], ^(NSNumber *x1, NSNumber *x2) {
            return @([x1 intValue] - [x2 intValue]) ;
            
        });
        NameOperation(sub);
        return sub;
    } forName:@"Subtract"];
    
    
    [DFWorkspace registerOperationCreationBlock:^DFOperation *{
        DFIdentityOperation *value = [DFIdentityOperation new];
        NameOperation(value);
        return value;
    } forName:@"Input"];
    
    
    [DFWorkspace registerOperationCreationBlock:^DFOperation *{
        DFOperation *splitter = OperationFromBlock([DFBackgroundOperation class], ^(NSString *text, NSString *separator) {
            return [text componentsSeparatedByString:separator] ;
        });
        [splitter setValue:@"," forKey:@"separator"];
        NameOperation(splitter);
        return splitter;
    } forName:@"TextSplitter"];
    
    [DFWorkspace registerOperationCreationBlock:^DFOperation *{
        DFOperation *intConverter = OperationFromBlock([DFBackgroundOperation class], ^(NSString *text) {
            return @([text integerValue]) ;
        });
        NameOperation(intConverter);
        return intConverter;
    } forName:@"IntConverter"];
    
    [DFWorkspace registerOperationCreationBlock:^DFOperation *{
        ArrayGenerator *seq = [ArrayGenerator generator];
        NameOperation(seq);
        return seq;
    } forName:@"ArraySequence"];
    
    [DFWorkspace registerOperationCreationBlock:^DFOperation *{
        DFAggregatorOperation *agg = [DFAggregatorOperation new];
        NameOperation(agg);
        return agg;
    } forName:@"Accumulator"];
    
    [DFWorkspace registerOperationCreationBlock:^DFOperation *{
        DFAnyOperation *any = [DFAnyOperation anyOperation:@[@"x1", @"x2"]];
        NameOperation(any);
        return any;
    } forName:@"Any"];
    
    [DFWorkspace registerOperationCreationBlock:^DFOperation *{
        DFAndOperation *and = [DFAndOperation andOperation:@[@"x1", @"x2"]];
        NameOperation(and);
        return and;
    } forName:@"And"];
   
    [DFWorkspace registerOperationCreationBlock:^DFOperation *{
        DFNetworkOperation *network = [DFNetworkOperation new];
        NameOperation(network);
        return network;
    } forName:@"Network"];
    
    [DFWorkspace registerOperationCreationBlock:^DFOperation *{
        DFOperation *urlConverter = OperationFromBlock([DFBackgroundOperation class], ^(NSString *text) {
            return [NSURLRequest requestWithURL:[NSURL URLWithString:text]] ;
        });
        NameOperation(urlConverter);
        return urlConverter;
    } forName:@"URLConverter"];
    
    [DFWorkspace registerOperationCreationBlock:^DFOperation *{
        DFOperation *arraySelector = OperationFromBlock([DFBackgroundOperation class], ^(NSArray *array, NSNumber *index) {
            NSUInteger idx = [index integerValue];
            return array[idx] ;
        });
        NameOperation(arraySelector);
        return arraySelector;
    } forName:@"ArraySelector"];
    
    [DFWorkspace registerOperationCreationBlock:^DFOperation *{
        DFOperation *flattenInput = [DFFlattenOperation new];
        NameOperation(flattenInput);
        return flattenInput;
    } forName:@"Flatten"];
    
    [DFWorkspace registerOperationCreationBlock:^DFOperation *{
        DFDelayOperation *delay = [DFDelayOperation new];
        NameOperation(delay);
        return delay;
    } forName:@"Delay"];
    
    [DFWorkspace registerOperationCreationBlock:^DFOperation *{
        SequenceGenerator *forSeq =  [SequenceGenerator generator];
        [forSeq setValue:@(1) forKey:@"inc"];
        NameOperation(forSeq);
        return forSeq;
    } forName:@"For"];
    
    [DFWorkspace registerOperationCreationBlock:^DFOperation *{
        RepeatGenerator *repeat =  [RepeatGenerator generator];
        NameOperation(repeat);
        return repeat;
    } forName:@"Repeat"];
    
    [DFWorkspace registerOperationCreationBlock:^DFOperation *{
        DFSelectorOperation *selector =  [DFSelectorOperation new];
        NameOperation(selector);
        return selector;
    } forName:@"Selector"];
    
    [DFWorkspace registerOperationCreationBlock:^DFOperation *{
        ForeverGenerator *forever =  [ForeverGenerator generator];
        NameOperation(forever);
        return forever;
    } forName:@"Forever"];
    
    [DFWorkspace registerOperationCreationBlock:^DFOperation *{
        DFLatestOperation *latest =  [DFLatestOperation new];
        NameOperation(latest);
        return latest;
    } forName:@"Latest"];
  
    [DFWorkspace registerOperationCreationBlock:^DFOperation *{
        DFBufferOperation *buffer =  [DFBufferOperation new];
        NameOperation(buffer);
        return buffer;
    } forName:@"Buffer"];
    
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
