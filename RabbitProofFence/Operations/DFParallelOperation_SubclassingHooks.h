//
//  DFParallelOperation_SubclassingHooks.h

//
//  Created by Sinha, Gyanendra on 6/23/14.

//
#import "DFParallelOperation.h"
#import "OperationInfo.h"
#import "DFReactiveOperation_SubclassingHooks.h"

@interface DFParallelOperation ()

@property (nonatomic, strong) NSMutableDictionary *operationsInProgress;

//default implementation calls the above block
- (id)outputForFinishedOperation:(DFOperation *)operation;

- (void)startOperations;

@end
