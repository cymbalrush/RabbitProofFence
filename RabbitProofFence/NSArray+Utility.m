//
//  NSArray+Number.m

//
//  Created by Henry Tsang on 9/10/14.

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
