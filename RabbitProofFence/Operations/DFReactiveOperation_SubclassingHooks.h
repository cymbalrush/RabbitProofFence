//
//  DFReactiveOperation_SubclassingHooks.h

//
//  Created by Sinha, Gyanendra on 6/23/14.

//

#import "DFReactiveOperation.h"
#import "ReactiveConnection.h"
#import "DFLoopOperation_SubclassingHooks.h"

@interface DFReactiveOperation ()

@property (strong, nonatomic) NSMutableDictionary *DF_reactiveConnections;

- (void)DF_reactiveConnectionPropertyChanged:(id)changedValue property:(NSString *)property operation:(DFOperation *)operation;

- (void)DF_reactiveConnectionStateChanged:(id)changedValue property:(NSString *)property operation:(DFOperation *)operation;

- (BOOL)DF_isReadyToExecute;

- (BOOL)DF_canExecute;

- (ReactiveConnection *)DF_newReactiveConnection;

- (BOOL)DF_isDone;

- (BOOL)DF_hasReactiveBindings;

- (void)DF_generateNextValues;

- (NSArray *)DF_operationsConnectedReactively;

- (NSDictionary *)DF_reactiveBindingsForOperation:(DFOperation *)operation;

- (void)DF_addPortToInputPorts:(NSString *)port;

- (void)next;

@end
