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

@class DFOperation;

@interface ReactiveConnectionInfo : NSObject

@property (strong, nonatomic) DFOperation *operation;

@property (assign, nonatomic) OperationState operationState;

@property (nonatomic, assign) int connectionCapacity;

@property (strong, nonatomic) NSMutableArray *inputs;

@property (strong, nonatomic) AMBlockToken *propertyObservationToken;

@property (strong, nonatomic) AMBlockToken *stateObservationToken;

@property (strong, nonatomic) NSString *connectedProperty;

- (void)clean;

- (void)addInput:(id)input;

@end
