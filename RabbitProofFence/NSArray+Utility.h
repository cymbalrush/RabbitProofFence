//
//  NSArray+Number.h
//  vf-hollywood
//
//  Created by Henry Tsang on 9/10/14.
//  Copyright (c) 2014 Conde Nast. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (Utility)

- (NSArray *)map:(id (^)(id obj, NSUInteger idx))block;

@end
