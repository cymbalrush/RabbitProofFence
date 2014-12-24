//
//  DFReactiveOperation.h
//  vf-hollywood
//
//  Created by Sinha, Gyanendra on 6/23/14.
//  Copyright (c) 2014 Conde Nast. All rights reserved.
//

#import "DFLoopOperation.h"

@interface DFReactiveOperation : DFLoopOperation

@property (assign, nonatomic) int connectionCapacity;

- (NSDictionary *)addReactiveDependency:(DFOperation *)operation withBindings:(NSDictionary *)bindings;

- (BOOL)connectPortReactively:(NSString *)port toOutputOfOperation:(id<Operation>)operation;

- (BOOL)isBindingReactive:(NSDictionary *)binding;

@end

