//
//  DFVoidObject.m

//
//  Created by Sinha, Gyanendra on 6/23/14.

//

#import "DFVoidObject.h"
#import "ExtRuntimeExtensions.h"

BOOL isDFVoidObject(id obj)
{
    return [obj isKindOfClass:[DFVoidObject class]];
}

@implementation DFVoidObjectException

@end

@implementation DFVoidObject

+ (instancetype)new
{
    return [[self class] alloc];
}

- (BOOL)respondsToSelector:(SEL)selector
{
    return NO;
}

- (BOOL)conformsToProtocol:(Protocol *)protocol
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

- (BOOL)isKindOfClass:(Class)class
{
    return [class isEqual:[DFVoidObject class]];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"Void, the answer to all questions"];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel
{
    NSString *reason = [NSString stringWithFormat:@"Void, the answer to all questions."];
    @throw [DFVoidObjectException exceptionWithName:NSStringFromClass([DFVoidObjectException class])
                                             reason:reason
                                           userInfo:nil];
    return nil;

    
}

@end
