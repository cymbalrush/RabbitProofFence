//
//  DFNetworkOperation.m
//  RabbitProofFence
//
//  Created by Sinha, Gyanendra on 12/24/14.
//  Copyright (c) 2014 Sinha, Gyanendra. All rights reserved.
//

#import "DFNetworkOperation.h"
#import "DFOperation_SubclassingHooks.h"

@interface DFNetworkOperation ()

@property (strong, nonatomic) NSURLSessionDataTask *task;

@end

@implementation DFNetworkOperation

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.inputPorts = @[@keypath(self.request)];
    }
    return self;
}

- (instancetype)clone:(NSMutableDictionary *)objToPointerMapping
{
    __block DFNetworkOperation *operation = nil;
    dispatch_block_t block = ^() {
        operation = [super clone:objToPointerMapping];
        operation.request = self.request;
    };
    [self safelyExecuteBlock:block];
    return operation;
}

- (instancetype)copyWithZone:(NSZone *)zone
{
    __block DFNetworkOperation *operation = nil;
    dispatch_block_t block = ^() {
        operation = [super copyWithZone:zone];
        operation.request = self.request;
    };
    [self safelyExecuteBlock:block];
    return operation;
}

- (void)suspend
{
    dispatch_block_t block = ^() {
        [super suspend];
        if (self.task.state == NSURLSessionTaskStateRunning) {
            [self.task suspend];
        }
    };
    [self safelyExecuteBlock:block];
}

- (void)resume
{
    dispatch_block_t block = ^() {
        [super resume];
        if (self.task.state == NSURLSessionTaskStateSuspended) {
            [self.task resume];
        }
    };
    [self safelyExecuteBlock:block];
}

- (void)cancel
{
    dispatch_block_t block = ^() {
        [super cancel];
        if (self.state == OperationStateExecuting) {
            [self done];
            [self.task cancel];
        }
    };
    [self safelyExecuteBlock:block];
}

- (void)main
{
    dispatch_block_t block = ^(void) {
        if (self.state != OperationStateExecuting) {
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
                if (self.state != OperationStateExecuting) {
                    return;
                }
                if (error) {
                    self.error = error;
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
                                self.error = encodingError;
                                self.output = nil;
                            }
                            else {
                                self.output = text;
                            }
                        }
                    }
                    self.output = text;
                }
                [self done];
            };
            [self safelyExecuteBlock:block];
        };
        self.task = [session dataTaskWithRequest:self.request completionHandler:completionHandler];
        if (self.task) {
            [self.task resume];
        }
        else  {
            [self done];
        }
    };
    [self safelyExecuteBlock:block];
}

@end
