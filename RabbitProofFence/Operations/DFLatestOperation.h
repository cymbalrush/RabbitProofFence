//
//  DFLatestOperation.h
//  FBP
//
//  Created by Sinha, Gyanendra on 1/7/15.
//  Copyright (c) 2015 Sinha, Gyanendra. All rights reserved.
//

#import "DFMapOperation.h"

@interface DFLatestOperation : DFMapOperation

@property (strong, nonatomic) id input;

@property (strong, nonatomic) NSNumber *bufferLimit;

@end
