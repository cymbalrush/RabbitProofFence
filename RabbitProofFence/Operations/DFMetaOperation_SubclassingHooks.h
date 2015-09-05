//
//  DFOperation_SubclassingHooks.h

//
//  Created by Sinha, Gyanendra on 6/23/14.

//

#import "DFMetaOperation.h"
#import "OperationInfo.h"
#import "DFOperation_SubclassingHooks.h"

@interface DFMetaOperation ()

@property (strong, nonatomic) DFOperation *DF_operation;

@property (strong, nonatomic) OperationInfo *DF_runningOperationInfo;

@property (readonly, nonatomic) BOOL DF_isExecutingOperation;

+ (NSDictionary *)DF_freePortsToOperationMapping:(DFOperation *)operation;

- (void)DF_prepareOperation:(DFOperation *)operation;

- (void)DF_startOperation:(DFOperation *)operation;

- (void)DF_operation:(DFOperation *)operation stateChanged:(id)changedValue;

- (AMBlockToken *)DF_startObservingOperation:(DFOperation *)operation;

@end
