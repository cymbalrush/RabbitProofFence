//
//  NSArray+Number.m
//  vf-hollywood
//
//  Created by Henry Tsang on 9/10/14.
//  Copyright (c) 2014 Conde Nast. All rights reserved.
//

#import "NSArray+Utility.h"

@implementation NSArray (Utility)

- (NSArray *)map:(id (^)(id obj, NSUInteger idx))block
{
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:[self count]];
    [self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        id mappedObj = block(obj, idx);
        if (mappedObj) {
            [result addObject:mappedObj];
        }
    }];
    return result;
}


@end
