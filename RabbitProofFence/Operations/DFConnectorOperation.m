//
//  DFConnectorOperation.m
//  vf-hollywood
//
//  Created by Sinha, Gyanendra on 7/2/14.
//  Copyright (c) 2014 Conde Nast. All rights reserved.
//

#import "DFConnectorOperation.h"
#import "DFOperation_SubclassingHooks.h"

@interface DFConnectorOperation ()

@property (strong, nonatomic) NSObject *DF_object;

@property (strong, nonatomic) NSString *DF_property;

@property (strong, nonatomic) AMBlockToken *DF_propertyObservationToken;

@end

@implementation DFConnectorOperation

+ (instancetype)operationFromBlock:(id)block ports:(NSArray *)ports
{
    methodNotSupported();
    return nil;
}

+ (instancetype)connectorFromObject:(NSObject *)object property:(NSString *)property
{
    return [[DFConnectorOperation alloc] initWithObject:object property:property];
}

+ (void)DF_startOperation:(DFOperation *)operation
{
    //start it immediately
    if (operation.DF_state == OperationStateReady) {
        [operation start];
    }
}
- (instancetype)initWithObject:(NSObject *)object property:(NSString *)property
{
    self = [super init];
    if (self) {
        _DF_object = object;
        _DF_property = property;
        _useCurrentValue = NO;
    }
    return self;
}

- (void)dealloc
{
    [self cancel];
}

- (instancetype)DF_clone:(NSMutableDictionary *)objToPointerMapping
{
    __block DFConnectorOperation *newConnectorOperation = nil;
    dispatch_block_t block = ^() {
        newConnectorOperation = [super DF_clone:objToPointerMapping];
        newConnectorOperation.DF_object = self.DF_object;
        newConnectorOperation.DF_property = self.DF_property;
        newConnectorOperation.useCurrentValue = self.useCurrentValue;
    };
    [self DF_safelyExecuteBlock:block];
    return newConnectorOperation;
}

- (instancetype)copyWithZone:(NSZone *)zone
{
    __block DFConnectorOperation *newConnectorOperation = nil;
    dispatch_block_t block = ^() {
        newConnectorOperation = [super copyWithZone:zone];
        newConnectorOperation.DF_object = self.DF_object;
        newConnectorOperation.DF_property = self.DF_property;
        newConnectorOperation.useCurrentValue = self.useCurrentValue;
    };
    [self DF_safelyExecuteBlock:block];
    return newConnectorOperation;
}

- (void)object:(NSObject *)object valueChanged:(id)changedValue
{
    dispatch_block_t block = ^() {
        if (self.DF_state != OperationStateExecuting) {
            return;
        }
        self.DF_output = changedValue;
    };
    [self DF_safelyExecuteBlock:block];
}

- (NSObject *)object
{
    return self.DF_object;
}

- (NSString *)property
{
    return self.DF_property;
}

- (void)cancel
{
    [super cancel];
    dispatch_block_t block = ^(void) {
        if (self.DF_propertyObservationToken) {
            [self.DF_object removeObserverWithBlockToken:self.DF_propertyObservationToken];
            self.DF_propertyObservationToken = nil;
        }
        self.DF_state = OperationStateDone;
    };
    [self DF_safelyExecuteBlock:block];
}

- (void)main
{
    dispatch_block_t block = ^(void) {
        if (self.DF_state != OperationStateExecuting) {
            return;
        }
        if (self.useCurrentValue) {
            self.DF_output = [self.DF_object valueForKey:self.DF_property];
        }
        @weakify(self);
        dispatch_queue_t observationQueue = [[self class] DF_observationQueue];
        AMBlockToken *token = [self.DF_object addObserverForKeyPath:self.DF_property task:^(id obj, NSDictionary *change) {
            id newValue = change[NSKeyValueChangeNewKey];
            dispatch_async(observationQueue, ^{
                @strongify(self);
                [self object:obj valueChanged:newValue];
            });
        }];
        self.DF_propertyObservationToken = token;
    };
    [self DF_safelyExecuteBlock:block];
}

@end
