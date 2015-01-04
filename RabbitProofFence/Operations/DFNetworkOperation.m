//
//  DFNetworkOperation.m
//  RabbitProofFence
//
//  Created by Sinha, Gyanendra on 12/24/14.
//  Copyright (c) 2014 Sinha, Gyanendra. All rights reserved.
//

#import "DFNetworkOperation.h"
#import "DFOperation_SubclassingHooks.h"

NSString * const DFNetworkOperationQueueName = @"com.operations.networkQueue";

@interface DFNetworkOperation ()

@property (strong, nonatomic) NSURLSessionDataTask *DF_task;

@end

@implementation DFNetworkOperation

+ (NSOperationQueue *)operationQueue
{
    static NSOperationQueue *queue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = [[NSOperationQueue alloc] init];
        queue.name = DFNetworkOperationQueueName;
        //we need a queue for prioritizing operations
        [queue setMaxConcurrentOperationCount:4];
    });
    return queue;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.DF_inputPorts = @[@keypath(self.request)];
    }
    return self;
}

- (instancetype)DF_clone:(NSMutableDictionary *)objToPointerMapping
{
    __block DFNetworkOperation *operation = nil;
    dispatch_block_t block = ^() {
        operation = [super DF_clone:objToPointerMapping];
        operation.request = self.request;
    };
    [self DF_safelyExecuteBlock:block];
    return operation;
}

- (instancetype)copyWithZone:(NSZone *)zone
{
    __block DFNetworkOperation *operation = nil;
    dispatch_block_t block = ^() {
        operation = [super copyWithZone:zone];
        operation.request = self.request;
    };
    [self DF_safelyExecuteBlock:block];
    return operation;
}

- (void)suspend
{
    dispatch_block_t block = ^() {
        [super suspend];
        if (self.DF_task.state == NSURLSessionTaskStateRunning) {
            [self.DF_task suspend];
        }
    };
    [self DF_safelyExecuteBlock:block];
}

- (void)resume
{
    dispatch_block_t block = ^() {
        [super resume];
        if (self.DF_task.state == NSURLSessionTaskStateSuspended) {
            [self.DF_task resume];
        }
    };
    [self DF_safelyExecuteBlock:block];
}

- (void)cancel
{
    dispatch_block_t block = ^() {
        [super cancel];
        if (self.DF_state == OperationStateExecuting) {
            [self DF_done];
            [self.DF_task cancel];
        }
    };
    [self DF_safelyExecuteBlock:block];
}

- (void)main
{
    dispatch_block_t block = ^(void) {
        if (self.DF_state != OperationStateExecuting) {
            return;
        }
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        NSURLSession *session = [NSURLSession sessionWithConfiguration:config
                                                              delegate:nil
                                                         delegateQueue:self.queue ? self.queue : [NSOperationQueue mainQueue]];
        
        @weakify(self);
        void(^completionHandler)(NSData *data, NSURLResponse *response, NSError *error) = nil;
        completionHandler = ^(NSData *data, NSURLResponse *response, NSError *error) {
            @strongify(self);
            dispatch_block_t block = ^(void) {
                if (self.DF_state != OperationStateExecuting) {
                    return;
                }
                if (error) {
                    self.DF_error = error;
                    self.DF_output = errorObject(error);
                }
                else if (response) {
                    NSString *text = nil;
                    NSError *encodingError = nil;
                    if (data) {
                        @try {
                            NSStringEncoding encoding = NSUTF8StringEncoding;
                            NSString *encodingName = response.textEncodingName;
                            if (encodingName.length > 0) {
                                CFStringEncoding aEncoding = CFStringConvertIANACharSetNameToEncoding((CFStringRef)encodingName);
                                encoding = CFStringConvertEncodingToNSStringEncoding(aEncoding);
                            }
                            text = [[NSString alloc] initWithData:data encoding:encoding];
                        }
                        @catch (NSException *exception) {
                            encodingError = NSErrorFromException(exception);
                        }
                        @finally {
                            if (encodingError) {
                                self.DF_error = encodingError;
                                self.DF_output = errorObject(encodingError);
                            }
                            else {
                                self.DF_output = text;
                            }
                        }
                    }
                    self.DF_output = text;
                }
                [self DF_done];
            };
            [self DF_safelyExecuteBlock:block];
        };
        self.DF_task = [session dataTaskWithRequest:self.request completionHandler:completionHandler];
        if (self.DF_task) {
            [self.DF_task resume];
        }
        else  {
            [self DF_done];
        }
    };
    [self DF_safelyExecuteBlock:block];
}

@end
