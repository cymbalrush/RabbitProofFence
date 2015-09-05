//
//  DFTryCatchOperation.h

//
//  Created by Sinha, Gyanendra on 6/23/14.

//

#import "DFMetaOperation.h"

//DFTryCatchOperation first executes try operation, if try operation fails with an error
//and errorBlock returns 'YES' for error then it executes catch operation otherwise operation
//fails with error.

@interface DFTryCatchOperation : DFMetaOperation

- (instancetype)initWithTryOperation:(DFOperation *)tryOperation
                   andCatchOperation:(DFOperation *)catchOperation
                       andErrorBlock:(BOOL(^)(NSError *error, DFTryCatchOperation *operation))errorBlock;

@property (readonly, nonatomic) DFOperation *tryOperation;

@property (readonly, nonatomic) DFOperation *catchOperation;

@end
