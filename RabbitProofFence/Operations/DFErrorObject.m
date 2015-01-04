//
//  DFOutput.m
//  RabbitProofFence
//
//  Created by Sinha, Gyanendra on 1/2/15.
//  Copyright (c) 2015 Sinha, Gyanendra. All rights reserved.
//

#import "DFErrorObject.h"
#import "EXTKeyPathCoding.h"

BOOL isDFErrorObject(id obj)
{
    return [obj isKindOfClass:[DFErrorObject class]];
}

DFErrorObject *errorObject(NSError *error)
{
    DFErrorObject *errorObj = [DFErrorObject new];
    errorObj.error = error;
    return errorObj;
}

@implementation DFErrorObjectException

@end

@implementation DFErrorObject

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

- (void)forwardInvocation:(NSInvocation*)anInvocation
{
    NSString *reason = [NSString stringWithFormat:@"Attempt to use error object -> \n%@", self.error];
    @throw [DFErrorObjectException exceptionWithName:NSStringFromClass([DFErrorObjectException class])
                                              reason:reason
                                            userInfo:@{@keypath(self.error) : self.error}];
}

- (BOOL)isKindOfClass:(Class)class
{
    return [class isEqual:[DFErrorObject class]];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"Something bad has happened -> \n %@ ", self.error];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel
{
    NSString *reason = [NSString stringWithFormat:@"Attempt to use error object -> \n%@", self.error];
    @throw [DFErrorObjectException exceptionWithName:NSStringFromClass([DFErrorObjectException class])
                                              reason:reason
                                            userInfo:@{@keypath(self.error) : self.error}];
    return nil;
    
    
}

@end
