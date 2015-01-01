//
//  OperationInfo
//  vf-hollywood
//
//  Created by Sinha, Gyanendra on 6/23/14.
//  Copyright (c) 2014 Conde Nast. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSObject+BlockObservation.h"

@class DFOperation;

@interface ConnectionInfo : NSObject

@property (strong, nonatomic) DFOperation *operation;

@property (strong, nonatomic) NSString *fromPort;

@property (strong, nonatomic) NSString *toPort;

@end
