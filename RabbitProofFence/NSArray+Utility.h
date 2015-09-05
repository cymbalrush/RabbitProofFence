//
//  NSArray+Number.h

//
//  Created by Henry Tsang on 9/10/14.

//

#import <Foundation/Foundation.h>

@interface NSArray (Utility)

- (NSArray *)map:(id (^)(id obj, NSUInteger idx))block;

@end
