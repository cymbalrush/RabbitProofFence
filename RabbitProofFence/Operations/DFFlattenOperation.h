//
//  DFSplitterOperation.h

//
//  Created by Sinha, Gyanendra on 8/1/14.

//

#import "DFMapOperation.h"

@interface DFFlattenOperation : DFMapOperation

@property (strong, nonatomic) NSArray *input;

+ (DFFlattenOperation *)flattenOperation;

@end
