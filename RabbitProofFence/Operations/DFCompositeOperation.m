//
//  DFCompositeOperation.m

//
//  Created by Sinha, Gyanendra on 6/23/14.

//

#import "DFCompositeOperation.h"
#import "DFMetaOperation_SubclassingHooks.h"

@implementation DFCompositeOperation

- (void)DF_prepareOperation:(DFOperation *)operation
{
    dispatch_block_t block = ^() {
        NSDictionary *mapping = [[self class] DF_freePortsToOperationMapping:operation];
        [self.DF_inputPorts enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSString *port = obj;
            NSSet *operations = mapping[port];
            id value = [self DF_portValue:port];
            [operations enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
                DFOperation *operation = obj;
                [operation setValue:value forKey:port];
            }];
        }];
    };
    [self DF_safelyExecuteBlock:block];
}

@end
