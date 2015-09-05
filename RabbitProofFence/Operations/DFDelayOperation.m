//
//  DFWaitOperation.m

//
//  Created by Sinha, Gyanendra on 6/23/14.

//

#import "DFDelayOperation.h"
#import "DFOperation_SubclassingHooks.h"

@implementation DFDelayOperation

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
        NSArray *ports = @[@keypath(self.input), @keypath(self.delay)];
        self.DF_inputPorts = ports;
        id (^block)(id input, NSNumber *delay) = ^(id input, NSNumber *delay) {
            return input;
        };
        self.executionBlock = block;
        [self DF_populateTypesFromBlock:block ports:ports];
    }
    return self;
}

- (Class)portType:(NSString *)port
{
    __block Class type = nil;
    dispatch_block_t block = ^(void) {
        type = [super portType:port];
        if ([port isEqualToString:@keypath(self.DF_output)] || [port isEqualToString:@keypath(self.output)]) {
            type = [super portType:@keypath(self.input)];
        }
    };
    [self DF_safelyExecuteBlock:block];
    return type;
}

- (void)main
{
    if ([self.delay doubleValue] == 0) {
        [self DF_execute];
    }
    else {
        @weakify(self);
        dispatch_block_t block = ^(void) {
            @strongify(self);
            [self DF_execute];
        };
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)([self.delay doubleValue] * NSEC_PER_SEC)), queue, block);
    }
}

@end
