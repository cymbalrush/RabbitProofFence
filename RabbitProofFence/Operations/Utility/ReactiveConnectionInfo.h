//
//  ReactiveConnectionInfo.h
//  vf-hollywood
//
//  Created by Sinha, Gyanendra on 6/23/14.
//  Copyright (c) 2014 Conde Nast. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSObject+BlockObservation.h"
#import "DFOperation.h"
#import "ConnectionInfo.h"

@class DFOperation;

@interface ReactiveConnectionInfo : ConnectionInfo

@property (assign, nonatomic) OperationState operationState;

@property (assign, nonatomic) int connectionCapacity;

@property (readonly, nonatomic) NSMutableArray *inputs;

@property (strong, nonatomic) AMBlockToken *stateObservationToken;

@property (strong, nonatomic) AMBlockToken *propertyObservationToken;

- (void)clean;

- (void)addInput:(id)input;

@end
