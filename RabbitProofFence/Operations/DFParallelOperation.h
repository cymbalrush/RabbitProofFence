//
//  DFParallelOperation.h

//
//  Created by Sinha, Gyanendra on 6/23/14.

//

#import "DFReactiveOperation.h"

@interface DFParallelOperation : DFReactiveOperation

@property (assign, nonatomic) NSUInteger maxConcurrentOperations;

@property (assign, nonatomic) BOOL outputInOrder;

@end
