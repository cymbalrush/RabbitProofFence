//
//  UIView+DebugObject.m
//  RabbitProofFence
//
//  Created by Sinha, Gyanendra on 11/7/14.
//  Copyright (c) 2014 Sinha, Gyanendra. All rights reserved.
//

#import "UIView+DebugObject.h"

@implementation UIView (DebugObject)

- (id)debugQuickLookObject
{
    if (self.frame.size.width * self.frame.size.height == 0) {
        return nil;
    }
    UIGraphicsBeginImageContextWithOptions(self.frame.size, YES, 0.0f);
    CGContextRef context = UIGraphicsGetCurrentContext();
    [self.layer renderInContext:context];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end
