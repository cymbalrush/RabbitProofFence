//
//  DFOperation_SubclassingHooks.h
//  vf-hollywood
//
//  Created by Sinha, Gyanendra on 6/23/14.
//  Copyright (c) 2014 Conde Nast. All rights reserved.
//

#import "DFMetaOperation.h"
#import "DFOperation_SubclassingHooks.h"

@interface DFMetaOperation ()

@property (strong, nonatomic) DFOperation *operation;

@property (strong, nonatomic) DFOperation *executingOperation;

@property (strong, nonatomic) AMBlockToken *operationObservationToken;

@property (readonly, nonatomic) BOOL isExecutingOperation;

+ (NSDictionary *)freePortsToOperationMapping:(DFOperation *)operation;

- (void)prepareOperation:(DFOperation *)operation;

- (void)startOperation:(DFOperation *)operation;

- (void)operation:(DFOperation *)operation stateChanged:(id)changedValue;

- (AMBlockToken *)startObservingOperation:(DFOperation *)operation;

@end
