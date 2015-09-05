//
//  DFWaitOperation.h

//
//  Created by Sinha, Gyanendra on 6/23/14.

//

#import "DFOperation.h"

@interface DFDelayOperation : DFOperation

@property (strong, nonatomic) NSNumber *delay;

@property (strong, nonatomic) id input;

+ (instancetype)operation;

@end
