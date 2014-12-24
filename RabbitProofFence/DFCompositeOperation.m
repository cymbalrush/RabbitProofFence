//
//  DFCompositeOperation.m
//  vf-hollywood
//
//  Created by Sinha, Gyanendra on 6/23/14.
//  Copyright (c) 2014 Conde Nast. All rights reserved.
//

#import "DFCompositeOperation.h"
#import "DFMetaOperation_SubclassingHooks.h"

@implementation DFCompositeOperation

- (void)prepareOperation:(DFOperation *)operation
{
    dispatch_block_t block = ^() {
        NSDictionary *mapping = [[self class] freePortsToOperationMapping:operation];
        [self.inputPorts enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSString *property = obj;
            NSSet *operations = [mapping objectForKey:property];
            id value = [self valueForKey:property];
            value = (value == [EXTNil null]) ? nil : value;
            [operations enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
                DFOperation *operation = obj;
                [operation setValue:value forKey:property];
            }];
        }];
    };
    [self safelyExecuteBlock:block];
}

@end
