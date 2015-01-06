//
//  DFSelectorOperation.m
//  RabbitProofFence
//
//  Created by Sinha, Gyanendra on 1/5/15.
//  Copyright (c) 2015 Sinha, Gyanendra. All rights reserved.
//

#import "DFSelectorOperation.h"
#import "DFOperation_SubclassingHooks.h"

@implementation DFSelectorOperation

+ (instancetype)operationFromBlock:(id)block ports:(NSArray *)ports
{
    methodNotSupported();
    return nil;
}

+ (instancetype)operation
{
    return [self new];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSArray *ports = @[@keypath(self.object), @keypath(self.selector)];
        self.DF_inputPorts = ports;
        id (^block)(id object, NSString *selector) = ^(id object, NSString *selector) {
            SEL sel = NSSelectorFromString(selector);
            id output = [DFVoidObject new];
            if (sel && [object respondsToSelector:sel]) {
                NSMethodSignature *sig = [NSMethodSignature methodSignatureForSelector:sel];
                const char *returnType = [sig methodReturnType];
                const char idType = @encode(id)[0];
                IMP imp = [object methodForSelector:sel];
                if ([sig methodReturnLength] == 0) {
                    void (*func)(id, SEL) = (void *)imp;
                    func(object, sel);
                }
                else if ([sig methodReturnLength] > 0 && returnType[0] == idType) {
                    id (*func)(id, SEL) = (void *)imp;
                    output = func(object, sel);
                }
            }
            return output;
        };
        self.executionBlock = block;
        [self DF_populateTypesFromBlock:block ports:ports];
    }
    return self;
}

@end
