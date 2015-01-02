//
//  DFTryCatchOperation.h
//  vf-hollywood
//
//  Created by Sinha, Gyanendra on 6/23/14.
//  Copyright (c) 2014 Conde Nast. All rights reserved.
//

#import "DFMetaOperation.h"

//DFTryCatchOperation first executes try operation, if try operation fails with an error
//and errorBlock returns 'YES' for error then it executes catch operation otherwise operation
//fails with error.

@interface DFTryCatchOperation : DFMetaOperation

- (instancetype)initWithTryOperation:(DFOperation *)tryOperation
                   andCatchOperation:(DFOperation *)catchOperation
                      andErrorBlock:(BOOL(^)(NSError *error))errorBlock;

@end
