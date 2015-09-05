//
//  DFVoidObject.h

//
//  Created by Sinha, Gyanendra on 6/23/14.

//

#import <Foundation/Foundation.h>

extern BOOL isDFVoidObject(id obj);

@interface DFVoidObjectException : NSException

@end

@interface DFVoidObject : NSProxy

+ (instancetype)new;

@end
