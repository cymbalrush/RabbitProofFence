//
//  DFNetworkOperation.h
//  RabbitProofFence
//
//  Created by Sinha, Gyanendra on 12/24/14.
//  Copyright (c) 2014 Sinha, Gyanendra. All rights reserved.
//

#import "DFOperation.h"

@interface DFNetworkOperation : DFOperation

@property (nonatomic, strong) NSURLRequest *request;

@property (nonatomic, strong) NSString *method;

@end
