//
//  DFObjectSplitter.h
//  vf-hollywood
//
//  Created by Sinha, Gyanendra on 7/25/14.
//  Copyright (c) 2014 Conde Nast. All rights reserved.
//

#import "DFOperation.h"
#import "DFBackgroundOperation.h"

@interface DFLiftOperation : DFBackgroundOperation

+ (instancetype)operationFromPorts:(NSArray *)ports;

- (instancetype)initWithPorts:(NSArray *)ports;

- (instancetype)initWithObject:(id<NSObject>)object ports:(NSArray *)ports;

@property (strong, nonatomic) NSObject *object;

//don't use it to connect
@property (readonly, nonatomic) id output OPERATION_INVALID_PORT;

@end


