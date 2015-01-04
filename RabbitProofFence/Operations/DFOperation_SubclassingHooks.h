//
//  CDOperation_SubclassingHooks.h
//  OperationalExcellence
//
//  Created by Sinha, Gyanendra on 11/29/13.
//  Copyright (c) 2013 GS. All rights reserved.
//

#import "DFOperation.h"
#import "OperationInfo.h"
#import "Execution_Class.h"
#import "metamacros.h"
#import "EXTKeyPathCoding.h"
#import "EXTScope.h"
#import "NSObject+BlockObservation.h"
#import "DFVoidObject.h"
#import "EXTNil.h"
#import "DFErrorObject.h"

extern NSString * const DFErrorKeyName;
extern const int DFOperationInComingPortErrorCode;

extern void methodNotSupported();
extern NSString *setterFromProperty(NSString *property);
extern NSDictionary *portErrors(NSError *error);
extern NSError *createErrorFromPortErrors(NSDictionary *portErrors);

@interface DFOperation ()

@property (assign, nonatomic) OperationState DF_state;

@property (strong, nonatomic) NSError *DF_error;

@property (strong, nonatomic) id DF_output;

@property (readonly, nonatomic) NSRecursiveLock *DF_operationLock;

@property (assign, nonatomic) BOOL DF_isSuspended;

@property (strong, nonatomic) Execution_Class *DF_executionObj;

@property (strong, nonatomic) NSArray *DF_inputPorts;

@property (strong, nonatomic) NSArray *DF_internalPorts;

@property (strong, nonatomic) NSMutableSet *DF_propertiesSet;

@property (strong, nonatomic) NSMutableSet *DF_excludedPorts;

@property (strong, nonatomic) NSMutableDictionary *DF_connections;

+ (Execution_Class *)DF_executionObjFromBlock:(id)block;

+ (NSOperationQueue *)operationQueue;

+ (dispatch_queue_t)DF_syncQueue;

+ (dispatch_queue_t)DF_startQueue;

+ (dispatch_queue_t)DF_observationQueue;

+ (NSMutableDictionary *)DF_dependentOperations;

+ (NSMutableSet *)DF_runningOperations;

+ (void)DF_startOperation:(DFOperation *)operation;

+ (void)DF_startDependentOperations:(DFOperation *)finishedOperation;

+ (void)DF_observeOperation:(DFOperation *)operation;

+ (void)DF_removeObservations:(DFOperation *)operation;

+ (void)DF_copyExcludedPortValuesFromOperation:(DFOperation *)fromOperation
                                toOperation:(DFOperation *)toOperation
                              excludedPorts:(NSSet *)excludedPorts;

- (void)DF_safelyRemoveObserver:(AMBlockToken *)token;

- (void)DF_safelyExecuteBlock:(dispatch_block_t)block;

- (instancetype)DF_clone;

- (instancetype)DF_clone:(NSMutableDictionary *)objToPointerMapping;

- (NSDictionary *)bindingsForOperation:(DFOperation *)operation;

- (NSSet *)DF_validBindingsForOperation:(DFOperation *)operation bindings:(NSDictionary *)bindings;

- (NSError *)DF_incomingPortErrors;

- (BOOL)DF_isPropertySet:(NSString *)property;

- (id)DF_correctedValue:(id)value forPort:(NSString *)port;

- (void)DF_executeBindings;

- (BOOL)DF_execute;

- (void)DF_prepareForExecution;

- (void)DF_prepareExecutionObj:(Execution_Class *)executionObj;

- (void)DF_breakRefCycleForExecutionObj:(Execution_Class *)executionObj;

- (void)DF_done;

@end
