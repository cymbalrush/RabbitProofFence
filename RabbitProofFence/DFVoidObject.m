//
//  DFVoidObject.m
//  vf-hollywood
//
//  Created by Sinha, Gyanendra on 6/23/14.
//  Copyright (c) 2014 Conde Nast. All rights reserved.
//

#import "DFVoidObject.h"
#import "ExtRuntimeExtensions.h"

@interface DFVoidObjectException : NSException

@end

@implementation DFVoidObjectException

@end

@implementation DFVoidObject

+ (instancetype)new
{
    return [[self class] alloc];
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
    return NO;
}

- (void) forwardInvocation:(NSInvocation*)anInvocation
{
    NSString *reason = [NSString stringWithFormat:@"Void, the answer to all questions."];
    @throw [DFVoidObjectException exceptionWithName:NSStringFromClass([DFVoidObjectException class])
                                             reason:reason
                                           userInfo:nil];
}


@end
