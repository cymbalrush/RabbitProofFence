//
//  DFVoidObject.h
//  vf-hollywood
//
//  Created by Sinha, Gyanendra on 6/23/14.
//  Copyright (c) 2014 Conde Nast. All rights reserved.
//

#import <Foundation/Foundation.h>

extern BOOL isVoid(id obj);

@interface DFVoidObject : NSProxy

+ (instancetype)new;

@end