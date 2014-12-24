//
//  DFAnyOperation.h
//  vf-hollywood
//
//  Created by Sinha, Gyanendra on 6/23/14.
//  Copyright (c) 2014 Conde Nast. All rights reserved.
//

#import "DFReactiveOperation.h"

@interface DFAnyOperation : DFReactiveOperation

+ (instancetype)anyOperation:(NSArray *)ports;

- (instancetype)initWithPorts:(NSArray *)ports;

@end
