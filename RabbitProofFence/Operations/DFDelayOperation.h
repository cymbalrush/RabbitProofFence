//
//  DFWaitOperation.h
//  vf-hollywood
//
//  Created by Sinha, Gyanendra on 6/23/14.
//  Copyright (c) 2014 Conde Nast. All rights reserved.
//

#import "DFOperation.h"

@interface DFDelayOperation : DFOperation

@property (strong, nonatomic) NSNumber *delay;

@property (strong, nonatomic) id input;

+ (instancetype)delayOperation;

@end
