//
//  DFReactiveOperation_SubclassingHooks.h
//  vf-hollywood
//
//  Created by Sinha, Gyanendra on 6/23/14.
//  Copyright (c) 2014 Conde Nast. All rights reserved.
//

#import "DFReactiveOperation.h"
#import "ReactiveConnectionInfo.h"
#import "DFLoopOperation_SubclassingHooks.h"

@interface DFReactiveOperation ()

@property (strong, nonatomic) NSMutableDictionary *DF_reactiveConnections;

- (void)DF_reactiveConnectionPropertyChanged:(id)changedValue property:(NSString *)property operation:(DFOperation *)operation;

- (void)DF_reactiveConnectionStateChanged:(id)changedValue property:(NSString *)property operation:(DFOperation *)operation;

- (BOOL)DF_isReadyToExecute;

- (BOOL)DF_canExecute;

- (ReactiveConnectionInfo *)DF_reactiveConnectionInfo;

- (BOOL)DF_isDone;

- (BOOL)DF_hasReactiveBindings;

- (void)DF_generateNextValues;

- (NSArray *)DF_operationsConnectedReactively;

- (NSDictionary *)DF_reactiveBindingsForOperation:(DFOperation *)operation;

- (void)DF_addPortToInputPorts:(NSString *)port;

@end
