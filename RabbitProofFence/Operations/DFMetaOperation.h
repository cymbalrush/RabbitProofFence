//
//  DFMetaOperation.h

//
//  Created by Sinha, Gyanendra on 6/23/14.

//

#import "DFOperation.h"

@interface DFMetaOperation : DFOperation

@property (readonly, nonatomic) DFOperation *DF_operation;

- (instancetype)initWithOperation:(DFOperation *)operation;

+ (instancetype)operationFromOperation:(DFOperation *)operation;

@end
