//
//  DFOutput.h
//  RabbitProofFence
//
//  Created by Sinha, Gyanendra on 1/2/15.
//  Copyright (c) 2015 Sinha, Gyanendra. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DFErrorObject;

BOOL isDFErrorObject(id obj);

DFErrorObject *errorObject(NSError *error);

@interface DFErrorObjectException : NSException

@end

@interface DFErrorObject : NSProxy

+ (instancetype)new;

@property (strong, nonatomic) NSError *error;

@end
