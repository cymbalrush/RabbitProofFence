//
//  DFTakeWhile.h
//  RabbitProofFence
//
//  Created by Sinha, Gyanendra on 12/31/14.
//  Copyright (c) 2014 Sinha, Gyanendra. All rights reserved.
//

#import "DFMapOperation.h"

@interface DFTakeWhileOperation : DFMapOperation

@property (strong, nonatomic) id input;

- (instancetype)initWithTakeWhileBlock:(BOOL (^)(id input))takeWhileBlock;

@end
