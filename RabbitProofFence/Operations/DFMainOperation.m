//
//  DFMainOperation.m
//  vf-hollywood
//
//  Created by Sinha, Gyanendra on 6/23/14.
//  Copyright (c) 2014 Conde Nast. All rights reserved.
//

#import "DFMainOperation.h"

@implementation DFMainOperation

+ (NSOperationQueue *)operationQueue
{
    return [NSOperationQueue mainQueue];
}

@end
