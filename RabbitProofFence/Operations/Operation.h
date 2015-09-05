//
//  Operation.h

//
//  Created by Sinha, Gyanendra on 6/23/14.

//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, OperationState) {
    OperationStateReady = 0,
    OperationStateExecuting,
    OperationStateDone
};

@protocol Operation <NSObject, NSCopying>

//block executed inside operation
@property (copy, nonatomic) id executionBlock;

//error property
@property (readonly, nonatomic) NSError *error;

//input ports
@property (readonly, nonatomic) NSArray *inputPorts;

//free ports
@property (readonly, nonatomic) NSArray *freePorts;

//output
@property (readonly, nonatomic) id output;

//current state
@property (readonly, nonatomic) OperationState state;

//self reference
@property (readonly, nonatomic) id<Operation> selfRef;

//returns 'YES' if operations is suspended otherwise 'NO'
@property (readonly, nonatomic) BOOL isSuspended;

//returns dependencies
@property (readonly, nonatomic) NSArray *connectedOperations;

//returns port types
@property (readonly, nonatomic) NSDictionary *portTypes;

//return free port types
@property (readonly, nonatomic) NSDictionary *freePortTypes;

/**
 * Designated initializer
 * @param block - execution block
 * @param ports - operation ports
 * @return initialized operation
**/
+ (instancetype)operationFromBlock:(id)block ports:(NSArray *)ports;

//puts each connected operation in it's queue and starts execution of operation graph, call this at root node
- (void)startExecution;

//cancels operation graph execution
- (void)cancelRecursively;

//suspend execution
- (void)suspend;

//resume execution
- (void)resume;

//visits each operation and sets it's priority
- (void)setQueuePriorityRecursively:(NSOperationQueuePriority)priority;

//adds dependency
- (void)addDependency:(id<Operation>)operation;

//adds dependency and connects ports, port(key) of operation is connected to value(port) of dependent operation
- (NSDictionary *)addDependency:(id<Operation>)operation withBindings:(NSDictionary *)bindings;

//adds dependency and connects output of operation to 'port'
- (BOOL)connectPort:(NSString *)port toOutputOfOperation:(id<Operation>)operation;

//removes port from free ports
- (void)excludePortFromFreePorts:(NSString *)port;

//removes ports from free ports
- (void)excludePortsFromFreePorts:(NSArray *)ports;

//connect operation 'output' to 'property' of 'object'
- (void)connectOutputToProperty:(NSString *)property ofObject:(NSObject *)object onQueue:(dispatch_queue_t)queue;

//remove 'output' connection to 'property' of 'object'
- (void)removeOutputConnectionsForObject:(NSObject *)object property:(NSString *)property;

//remove all connections to 'output' for 'object'
- (void)removeAllOutputConnectionsForObject:(NSObject *)object;

//returns port's class or nil, if id
- (Class)portType:(NSString *)port;

@end
