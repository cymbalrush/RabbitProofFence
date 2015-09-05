//
//  DFAnyOperation.h

//
//  Created by Sinha, Gyanendra on 6/23/14.

//

#import "DFReactiveOperation.h"

@interface DFAnyOperation : DFReactiveOperation

+ (instancetype)anyOperation:(NSArray *)ports;

- (instancetype)initWithPorts:(NSArray *)ports;

@end
