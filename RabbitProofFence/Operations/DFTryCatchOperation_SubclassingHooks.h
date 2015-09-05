//
//  DFTryCatchOperation_SubclassingHooks.h

//
//  Created by Sinha, Gyanendra on 6/23/14.

//

#import "CDTryCatchOperation.h"
#import "CDMetaOperation_SubclassingHooks.h"

@interface CDTryCatchOperation ()

@property (strong, nonatomic) CDOperation *tryOperation;

@property (strong, nonatomic) CDOperation *catchOperation;

@property (copy, nonatomic) NSString *errorDomain;

@end
