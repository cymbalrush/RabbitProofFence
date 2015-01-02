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

@property (strong, nonatomic) NSMutableDictionary *reactiveConnections;

- (void)reactiveConnectionPropertyChanged:(id)changedValue property:(NSString *)property operation:(DFOperation *)operation;

- (void)reactiveConnectionStateChanged:(id)changedValue property:(NSString *)property operation:(DFOperation *)operation;

- (BOOL)isReadyToExecute;

- (BOOL)canExecute;

- (ReactiveConnectionInfo *)reactiveConnectionInfo;

- (BOOL)isDone;

- (BOOL)hasReactiveBindings;

- (void)generateNextValues;

- (NSArray *)reactiveOperations;

- (NSDictionary *)reactiveBindingsForOperation:(DFOperation *)operation;

- (void)addPortToInputPorts:(NSString *)port;

@end
