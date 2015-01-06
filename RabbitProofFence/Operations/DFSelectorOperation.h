//
//  DFSelectorOperation.h
//  RabbitProofFence
//
//  Created by Sinha, Gyanendra on 1/5/15.
//  Copyright (c) 2015 Sinha, Gyanendra. All rights reserved.
//

#import "DFOperation.h"

@interface DFSelectorOperation : DFOperation

+ (instancetype)operation;

@property (strong, nonatomic) id object;

@property (strong, nonatomic) NSString *selector;

@end
