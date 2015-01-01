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

@property (nonatomic, weak) NSObject *object;
@property (nonatomic, strong) NSString *property;
@property (nonatomic, strong) AMBlockToken *propertyObservationToken;

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

+ (void)startOperation:(DFOperation *)operation
{
    //start it immediately
    if (operation.state == OperationStateReady) {
        [operation start];
    }
}
- (instancetype)initWithObject:(id<NSObject>)object property:(NSString *)property
{
    self = [super init];
    if (self) {
        _object = object;
        _property = [property copy];
    }
    return self;
}

- (void)dealloc
{
    [self cancel];
}

- (instancetype)clone:(NSMutableDictionary *)objToPointerMapping
{
    __block DFConnectorOperation *newConnectorOperation = nil;
    dispatch_block_t block = ^() {
        newConnectorOperation = [super clone:objToPointerMapping];
        newConnectorOperation.object = self.object;
        newConnectorOperation.property = [self.property copy];
        newConnectorOperation.useCurrentValue = self.useCurrentValue;
    };
    [self safelyExecuteBlock:block];
    return newConnectorOperation;
}

- (instancetype)copyWithZone:(NSZone *)zone
{
    __block DFConnectorOperation *newConnectorOperation = nil;
    dispatch_block_t block = ^() {
        newConnectorOperation = [super copyWithZone:zone];
        newConnectorOperation.object = self.object;
        newConnectorOperation.property = [self.property copy];
        newConnectorOperation.useCurrentValue = self.useCurrentValue;
    };
    [self safelyExecuteBlock:block];
    return newConnectorOperation;
}

- (void)cancel
{
    [super cancel];
    dispatch_block_t block = ^(void) {
        if (self.propertyObservationToken) {
            [self.object removeObserverWithBlockToken:self.propertyObservationToken];
            self.propertyObservationToken = nil;
        }
        self.state = OperationStateDone;
    };
    [self safelyExecuteBlock:block];
}

- (void)object:(NSObject *)object valueChanged:(id)changedValue
{
    dispatch_block_t block = ^() {
        if (self.state == OperationStateDone) {
            return;
        }
        self.output = changedValue;
    };
    [self safelyExecuteBlock:block];
}

- (void)main
{
    dispatch_block_t block = ^(void) {
        if (self.state != OperationStateExecuting) {
            return;
        }
        if (self.useCurrentValue) {
            self.output = [self.object valueForKey:self.property];
        }
        @weakify(self);
        dispatch_queue_t observationQueue = [[self class] operationObservationHandlingQueue];
        AMBlockToken *observationToken = [self.object addObserverForKeyPath:self.property task:^(id obj, NSDictionary *change) {
            id newValue = change[NSKeyValueChangeNewKey];
            dispatch_async(observationQueue, ^{
                @strongify(self);
                [self object:obj valueChanged:newValue];
            });
        }];
        self.propertyObservationToken = observationToken;
    };
    [self safelyExecuteBlock:block];
}

@end
