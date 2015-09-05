//
//  Execution_Class.m

//
//  Created by Sinha, Gyanendra on 6/23/14.

//

#import "Execution_Class.h"
#import "ExtNil.h"

@implementation Execution_Class

- (id)execute
{
    return nil;
}

- (void)purge
{
    NSUInteger n = [self numberOfPorts];
    for (int i = 0; i < n; i ++) {
        [self setValue:nil atArgIndex:i];
    }
}

- (NSUInteger)numberOfPorts
{
    NSString *className = NSStringFromClass([self class]);
    NSArray *array = [className componentsSeparatedByString:@"_"];
    NSString *lastComponent = [array lastObject];
    return [lastComponent intValue];
}

+ (instancetype)instanceForNumberOfArguments:(NSUInteger)nArgs
{
    NSString *className = [NSString stringWithFormat:@"Execution_Class_%lu", (unsigned long)nArgs];
    Class objClass = NSClassFromString(className);
    if (objClass) {
        return [objClass new];
    }
    //throw an execption, number of arguments not supported
    return nil;
}

- (void)setValue:(id)value atArgIndex:(NSUInteger)argIndex
{
    NSString *key = [NSString stringWithFormat:@"x_%lu", (unsigned long)argIndex];
    [self setValue:value forKey:key];
}

- (id)valueForArgAtIndex:(NSUInteger)argIndex
{
    NSString *key = [NSString stringWithFormat:@"x_%lu", (unsigned long)argIndex];
    return [self valueForKey:key];
}

- (instancetype)copyWithZone:(NSZone *)zone
{
    Execution_Class *copy = [[self class] new];
    copy.executionBlock = self.executionBlock;
    return copy;
}

- (NSArray *)valuesArray
{
    NSUInteger nPorts = [self numberOfPorts];
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:nPorts];
    for (int index = 0; index < nPorts; index++) {
        id value = [self valueForArgAtIndex:index];
        value = (value == nil) ? [EXTNil null] : value;
        [array addObject:value];
    }
    return array;
}

@end


@implementation Execution_Class_0

- (id)execute
{
    @autoreleasepool {
        id (^block)() = self.executionBlock;
        return block();
    }
}

@end

@implementation Execution_Class_1

- (id)execute
{
    @autoreleasepool {
        id (^block)(id x_0) = self.executionBlock;
        return block(self.x_0);
    }
}

@end

@implementation Execution_Class_2

- (id)execute
{
    @autoreleasepool {
        id (^block)(id x_0, id x_1) = self.executionBlock;
        return block(self.x_0, self.x_1);
   }
}

@end


@implementation Execution_Class_3

- (id)execute
{
    @autoreleasepool {
        id (^block)(id x_0, id x_1, id x_2) = self.executionBlock;
        return block(self.x_0, self.x_1, self.x_2);
    }
}

@end


@implementation Execution_Class_4

- (id)execute
{
    @autoreleasepool {
        id (^block)(id x_0, id x_1, id x_2, id x_3) = self.executionBlock;
        return block(self.x_0, self.x_1, self.x_2, self.x_3);
    }
}

@end


@implementation Execution_Class_5

- (id)execute
{
    @autoreleasepool {
        id (^block)(id x_0, id x_1, id x_2, id x_3, id x_4) = self.executionBlock;
        return block(self.x_0, self.x_1, self.x_2, self.x_3, self.x_4);
    }
}

@end


@implementation Execution_Class_6

- (id)execute
{
    @autoreleasepool {
        id (^block)(id x_0, id x_1, id x_2, id x_3, id x_4, id x_5) = self.executionBlock;
        return block(self.x_0, self.x_1, self.x_2, self.x_3, self.x_4, self.x_5);
    }
}

@end


@implementation Execution_Class_7

- (id)execute
{
    @autoreleasepool {
        id (^block)(id x_0, id x_1, id x_2, id x_3, id x_4, id x_5, id x_6) = self.executionBlock;
        return block(self.x_0, self.x_1, self.x_2, self.x_3, self.x_4, self.x_5, self.x_6);
    }
}

@end


@implementation Execution_Class_8

- (id)execute
{
    @autoreleasepool {
        id (^block)(id x_0, id x_1, id x_2, id x_3, id x_4, id x_5, id x_6, id x_7) = self.executionBlock;
        return block(self.x_0, self.x_1, self.x_2, self.x_3, self.x_4, self.x_5, self.x_6, self.x_7);
    }
}

@end


@implementation Execution_Class_9

- (id)execute
{
    @autoreleasepool {
        id (^block)(id x_0, id x_1, id x_2, id x_3, id x_4, id x_5, id x_6, id x_7, id x_8) = self.executionBlock;
        return block(self.x_0, self.x_1, self.x_2, self.x_3, self.x_4, self.x_5, self.x_6, self.x_7, self.x_8);
    }
}

@end


@implementation Execution_Class_10

- (id)execute
{
    @autoreleasepool {
        id (^block)(id x_0, id x_1, id x_2, id x_3, id x_4, id x_5, id x_6, id x_7, id x_8, id x_9) = self.executionBlock;
        return block(self.x_0, self.x_1, self.x_2, self.x_3, self.x_4, self.x_5, self.x_6, self.x_7, self.x_8, self.x_9);
    }
}

@end


@implementation Execution_Class_11

- (id)execute
{
    @autoreleasepool {
        id (^block)(id x_0, id x_1, id x_2, id x_3, id x_4, id x_5, id x_6, id x_7, id x_8, id x_9, id x_10) = self.executionBlock;
        return block(self.x_0, self.x_1, self.x_2, self.x_3, self.x_4, self.x_5, self.x_6, self.x_7, self.x_8, self.x_9, self.x_10);
    }
}

@end


@implementation Execution_Class_12

- (id)execute
{
    @autoreleasepool {
        id (^block)(id x_0, id x_1, id x_2, id x_3, id x_4, id x_5, id x_6, id x_7, id x_8, id x_9, id x_10, id x_11) = self.executionBlock;
        return block(self.x_0, self.x_1, self.x_2, self.x_3, self.x_4, self.x_5, self.x_6, self.x_7, self.x_8, self.x_9, self.x_10, self.x_11);
    }
}

@end


@implementation Execution_Class_13

- (id)execute
{
    @autoreleasepool {
        id (^block)(id x_0, id x_1, id x_2, id x_3, id x_4, id x_5, id x_6, id x_7, id x_8, id x_9, id x_10, id x_11, id x_12) = self.executionBlock;
        return block(self.x_0, self.x_1, self.x_2, self.x_3, self.x_4, self.x_5, self.x_6, self.x_7, self.x_8, self.x_9, self.x_10, self.x_11, self.x_12);
    }
}

@end


@implementation Execution_Class_14

- (id)execute
{
    @autoreleasepool {
        id (^block)(id x_0, id x_1, id x_2, id x_3, id x_4, id x_5, id x_6, id x_7, id x_8, id x_9, id x_10, id x_11, id x_12, id x_13) = self.executionBlock;
        return block(self.x_0, self.x_1, self.x_2, self.x_3, self.x_4, self.x_5, self.x_6, self.x_7, self.x_8, self.x_9, self.x_10, self.x_11, self.x_12, self.x_13);
    }
}

@end


@implementation Execution_Class_15

- (id)execute
{
    @autoreleasepool {
        id (^block)(id x_0, id x_1, id x_2, id x_3, id x_4, id x_5, id x_6, id x_7, id x_8, id x_9, id x_10, id x_11, id x_12, id x_13, id x_14) = self.executionBlock;
        return block(self.x_0, self.x_1, self.x_2, self.x_3, self.x_4, self.x_5, self.x_6, self.x_7, self.x_8, self.x_9, self.x_10, self.x_11, self.x_12, self.x_13, self.x_14);
    }
}

@end


@implementation Execution_Class_16

- (id)execute
{
    @autoreleasepool {
        id (^block)(id x_0, id x_1, id x_2, id x_3, id x_4, id x_5, id x_6, id x_7, id x_8, id x_9, id x_10, id x_11, id x_12, id x_13, id x_14, id x_15) = self.executionBlock;
        return block(self.x_0, self.x_1, self.x_2, self.x_3, self.x_4, self.x_5, self.x_6, self.x_7, self.x_8, self.x_9, self.x_10, self.x_11, self.x_12, self.x_13, self.x_14, self.x_15);
    }
}

@end

@implementation Execution_Class_17

- (id)execute
{
    @autoreleasepool {
        id (^block)(id x_0, id x_1, id x_2, id x_3, id x_4, id x_5, id x_6, id x_7, id x_8, id x_9, id x_10, id x_11, id x_12, id x_13, id x_14, id x_15, id x_16) = self.executionBlock;
        return block(self.x_0, self.x_1, self.x_2, self.x_3, self.x_4, self.x_5, self.x_6, self.x_7, self.x_8, self.x_9, self.x_10, self.x_11, self.x_12, self.x_13, self.x_14, self.x_15, self.x_16);
    }
}

@end

@implementation Execution_Class_18

- (id)execute
{
    @autoreleasepool {
        id (^block)(id x_0, id x_1, id x_2, id x_3, id x_4, id x_5, id x_6, id x_7, id x_8, id x_9, id x_10, id x_11, id x_12, id x_13, id x_14, id x_15, id x_16, id x_17) = self.executionBlock;
        return block(self.x_0, self.x_1, self.x_2, self.x_3, self.x_4, self.x_5, self.x_6, self.x_7, self.x_8, self.x_9, self.x_10, self.x_11, self.x_12, self.x_13, self.x_14, self.x_15, self.x_16, self.x_17);
    }
}

@end

@implementation Execution_Class_19

- (id)execute
{
    @autoreleasepool {
        id (^block)(id x_0, id x_1, id x_2, id x_3, id x_4, id x_5, id x_6, id x_7, id x_8, id x_9, id x_10, id x_11, id x_12, id x_13, id x_14, id x_15, id x_16, id x_17, id x_18) = self.executionBlock;
        return block(self.x_0, self.x_1, self.x_2, self.x_3, self.x_4, self.x_5, self.x_6, self.x_7, self.x_8, self.x_9, self.x_10, self.x_11, self.x_12, self.x_13, self.x_14, self.x_15, self.x_16, self.x_17, self.x_18);
    }
}

@end

@implementation Execution_Class_20

- (id)execute
{
    @autoreleasepool {
        id (^block)(id x_0, id x_1, id x_2, id x_3, id x_4, id x_5, id x_6, id x_7, id x_8, id x_9, id x_10, id x_11, id x_12, id x_13, id x_14, id x_15, id x_16, id x_17, id x_18, id x_19) = self.executionBlock;
        return block(self.x_0, self.x_1, self.x_2, self.x_3, self.x_4, self.x_5, self.x_6, self.x_7, self.x_8, self.x_9, self.x_10, self.x_11, self.x_12, self.x_13, self.x_14, self.x_15, self.x_16, self.x_17, self.x_18, self.x_19);
    }
}

@end

