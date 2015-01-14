//
//  DependentOperationInfo.h
//  vf-hollywood
//
//  Created by Sinha, Gyanendra on 6/23/14.
//  Copyright (c) 2014 Conde Nast. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Operation.h"
#import "NSObject+BlockObservation.h"

@class DFOperation;

@interface OperationInfo : NSObject

@property (strong, nonatomic) DFOperation *operation;

@property (assign, nonatomic) OperationState operationState;

@property (strong, nonatomic) AMBlockToken *stateObservationToken;

@property (strong, nonatomic) AMBlockToken *outputObservationToken;

- (void)clean;

@end
