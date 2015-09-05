//
//  DFReactiveOperation.h

//
//  Created by Sinha, Gyanendra on 6/23/14.

//

#import "DFLoopOperation.h"

@interface DFReactiveOperation : DFLoopOperation

@property (assign, nonatomic) int connectionCapacity;

@property (assign, nonatomic) BOOL hot;

- (NSDictionary *)addReactiveDependency:(DFOperation *)operation withBindings:(NSDictionary *)bindings;

- (BOOL)connectPortReactively:(NSString *)port toOutputOfOperation:(id<Operation>)operation;

- (BOOL)isBindingReactive:(NSDictionary *)binding;

@end

