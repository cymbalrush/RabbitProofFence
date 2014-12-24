//
//  DFMapOperation.h
//  vf-hollywood
//
//  Created by Sinha, Gyanendra on 6/23/14.
//  Copyright (c) 2014 Conde Nast. All rights reserved.
//

#import "DFReactiveOperation.h"

@interface DFMapOperation : DFReactiveOperation

- (instancetype)initWithMapBlock:(id)mapBlock ports:(NSArray *)ports;

@end
