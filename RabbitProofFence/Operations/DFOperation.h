//
//  DFOperation.h

//
//  Created by Sinha, Gyanendra on 6/23/14.

//

#import <Foundation/Foundation.h>
#import "Operation.h"

#define NameOperation(op) [op setName:[NSString stringWithUTF8String: #op]]

extern NSString * const DFOperationExceptionInvalidBlockSignature;
extern NSString * const DFOperationExceptionDuplicatePropertyNames;
extern NSString * const DFOperationExceptionName;
extern NSString * const DFOperationExceptionHandlerDomain;
extern NSString * const DFOperationExceptionReason;
extern NSString * const DFOperationExceptionUserInfo;
extern NSString * const DFOperationExceptionHandlerDomain;
extern NSString * const DFOperationExceptionInEqualPorts;
extern NSString * const DFOperationExceptionInvalidInitialization;
extern NSString * const DFOperationExceptionMethodNotSupported;
extern NSString * const DFOperationExceptionIncorrectParameter;
extern const int DFOperationExceptionEncounteredErrorCode;

#define OPERATION_INVALID_PORT 

//This will auto generate port names from block arguments
#define OperationFromBlock(OperationClass, Block)\
[OperationClass operationFromBlock:Block ports:portNamesFromBlockArgs(#Block)]

NSError * NSErrorFromException(NSException *exception);

NSArray *portNamesFromBlockArgs(const char *blockBody);

@interface DFOperation : NSOperation <Operation>

//queue which runs this operation
@property (strong, nonatomic) NSOperationQueue *queue;

- (BOOL)canConnectPort:(NSString *)port ofOperation:(DFOperation *)operation toPort:(NSString *)toPort;

//start queue
+ (void)startQueue;

//stop queue
+ (void)stopQueue;

@end


