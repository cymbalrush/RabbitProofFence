//
//  DFIdentityOperation.h
//  RabbitProofFence
//
//  Created by Sinha, Gyanendra on 11/20/14.
//  Copyright (c) 2014 Sinha, Gyanendra. All rights reserved.
//

#import "DFOperation.h"

@interface DFIdentityOperation : DFOperation

@property (strong, nonatomic) id input;

+ (instancetype)operation;

@end
