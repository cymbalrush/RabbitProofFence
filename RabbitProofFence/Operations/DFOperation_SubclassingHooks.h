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

@interface DFOperation ()

@property (assign, nonatomic) OperationState state;

@property (strong, nonatomic) NSError *error;

@property (strong, nonatomic) id output;

@property (readonly, nonatomic) NSRecursiveLock *operationLock;

@property (assign, nonatomic) BOOL isSuspended;

@property (strong, nonatomic) Execution_Class *executionObj;

@property (strong, nonatomic) NSArray *inputPorts;

@property (strong, nonatomic) NSMutableSet *propertiesSet;

@property (strong, nonatomic) NSMutableSet *excludedPorts;

@property (strong, nonatomic) NSMutableDictionary *connections;

+ (Execution_Class *)executionObjFromBlock:(id)block;

+ (NSOperationQueue *)operationQueue;

+ (dispatch_queue_t)syncQueue;

+ (dispatch_queue_t)operationStartQueue;

+ (dispatch_queue_t)operationObservationHandlingQueue;

+ (NSMutableDictionary *)dependentOperations;

+ (NSMutableSet *)executingOperations;

+ (void)startOperation:(DFOperation *)operation;

+ (void)startDependentOperations:(DFOperation *)finishedOperation;

+ (void)startObservingOperation:(DFOperation *)operation;

+ (void)removeObservations:(DFOperation *)operation;

+ (void)copyExcludedPortValuesFromOperation:(DFOperation *)fromOperation
                                toOperation:(DFOperation *)toOperation
                              excludedPorts:(NSSet *)excludedPorts;

- (void)safelyRemoveObserverWithBlockToken:(AMBlockToken *)token;

- (void)safelyExecuteBlock:(dispatch_block_t)block;

- (instancetype)clone;

- (instancetype)clone:(NSMutableDictionary *)objToPointerMapping;

- (NSArray *)connectedOperations;

- (NSArray *)freePorts;

- (NSDictionary *)bindingsForOperation:(DFOperation *)operation;

- (NSSet *)validBindingsForOperation:(DFOperation *)operation bindings:(NSDictionary *)bindings;

- (BOOL)isPropertySet:(NSString *)property;

- (void)executeBindings;

- (BOOL)execute;

- (void)prepareForExecution;

- (void)prepareExecutionObj:(Execution_Class *)executionObj;

- (void)breakRefCycleForExecutionObj:(Execution_Class *)executionObj;

- (void)done;

@end
