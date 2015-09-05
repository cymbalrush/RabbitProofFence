//
//  Execution_Class.h

//
//  Created by Sinha, Gyanendra on 6/23/14.

//

#import <Foundation/Foundation.h>

@interface Execution_Class : NSObject <NSCopying>

@property (copy, nonatomic) id executionBlock;

+ (instancetype)instanceForNumberOfArguments:(NSUInteger)nArgs;

- (id)execute;

- (id)valueForArgAtIndex:(NSUInteger)argIndex;

- (void)setValue:(id)value atArgIndex:(NSUInteger)argIndex;

- (NSUInteger)numberOfPorts;

- (NSArray *)valuesArray;

- (void)purge;

@end


@interface Execution_Class_0 : Execution_Class

@end

@interface Execution_Class_1 : Execution_Class_0

@property (strong, nonatomic) id x_0;

@end


@interface Execution_Class_2 : Execution_Class_1

@property (strong, nonatomic) id x_1;

@end


@interface Execution_Class_3 : Execution_Class_2

@property (strong, nonatomic) id x_2;

@end


@interface Execution_Class_4 : Execution_Class_3

@property (strong, nonatomic) id x_3;

@end

@interface Execution_Class_5 : Execution_Class_4

@property (strong, nonatomic) id x_4;

@end

@interface Execution_Class_6 : Execution_Class_5

@property (strong, nonatomic) id x_5;

@end

@interface Execution_Class_7 : Execution_Class_6

@property (strong, nonatomic) id x_6;

@end

@interface Execution_Class_8 : Execution_Class_7

@property (strong, nonatomic) id x_7;

@end

@interface Execution_Class_9 : Execution_Class_8

@property (strong, nonatomic) id x_8;

@end

@interface Execution_Class_10 : Execution_Class_9

@property (strong, nonatomic) id x_9;

@end

@interface Execution_Class_11 : Execution_Class_10

@property (strong, nonatomic) id x_10;

@end


@interface Execution_Class_12 : Execution_Class_11

@property (strong, nonatomic) id x_11;

@end


@interface Execution_Class_13 : Execution_Class_12

@property (strong, nonatomic) id x_12;

@end

@interface Execution_Class_14 : Execution_Class_13

@property (strong, nonatomic) id x_13;

@end

@interface Execution_Class_15 : Execution_Class_14

@property (strong, nonatomic) id x_14;

@end


@interface Execution_Class_16 : Execution_Class_15

@property (strong, nonatomic) id x_15;

@end

@interface Execution_Class_17 : Execution_Class_16

@property (strong, nonatomic) id x_16;

@end

@interface Execution_Class_18 : Execution_Class_17

@property (strong, nonatomic) id x_17;

@end

@interface Execution_Class_19 : Execution_Class_18

@property (strong, nonatomic) id x_18;

@end

@interface Execution_Class_20 : Execution_Class_19

@property (strong, nonatomic) id x_19;

@end