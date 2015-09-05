//
//  DFIfElseOperation.h

//
//  Created by Sinha, Gyanendra on 6/23/14.

//

#import "DFMetaOperation.h"

@interface DFIfElseOperation : DFMetaOperation

@property (readonly, nonatomic) DFOperation *ifOperation;

@property (readonly, nonatomic) DFOperation *elseOperation;

@property (readonly, nonatomic) NSPredicate *predicate;

+(DFIfElseOperation *)ifElseOperationFromIfOperation:(DFOperation *)ifOperation
                                       elseOperation:(DFOperation *)elseOperation
                                           predicate:(NSPredicate *)predicate;

- (instancetype)initWithIfOperation:(DFOperation *)ifOperation
                      elseOperation:(DFOperation *)elseOperation
                          predicate:(NSPredicate *)predicate;


@end
