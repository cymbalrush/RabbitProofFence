//
//  DFConnectorOperation.h
//  vf-hollywood
//
//  Created by Sinha, Gyanendra on 7/2/14.
//  Copyright (c) 2014 Conde Nast. All rights reserved.
//

#import "DFOperation.h"
#import "StreamOperation.h"

#define DFConnector(object, objProperty)\
[DFConnectorOperation connectorFromObject:object property:objProperty]

@interface DFConnectorOperation : DFOperation <StreamOperation>

@property (nonatomic, readonly) NSObject *object;

@property (nonatomic, readonly) NSString *property;

@property (nonatomic, assign) BOOL useCurrentValue;

+ (instancetype)connectorFromObject:(id<NSObject>)object property:(NSString *)property;

- (instancetype)initWithObject:(id<NSObject>)object property:(NSString *)property;

@end
