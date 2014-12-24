//
//  DFTryCatchOperation_SubclassingHooks.h
//  vf-hollywood
//
//  Created by Sinha, Gyanendra on 6/23/14.
//  Copyright (c) 2014 Conde Nast. All rights reserved.
//

#import "CDTryCatchOperation.h"
#import "CDMetaOperation_SubclassingHooks.h"

@interface CDTryCatchOperation ()

@property (strong, nonatomic) CDOperation *tryOperation;

@property (strong, nonatomic) CDOperation *catchOperation;

@property (copy, nonatomic) NSString *errorDomain;

@end
