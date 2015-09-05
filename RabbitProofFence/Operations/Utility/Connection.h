//
//  OperationInfo

//
//  Created by Sinha, Gyanendra on 6/23/14.

//

#import <Foundation/Foundation.h>
#import "NSObject+BlockObservation.h"

@class DFOperation;

@interface Connection : NSObject

@property (strong, nonatomic) DFOperation *operation;

@property (strong, nonatomic) NSString *fromPort;

@property (strong, nonatomic) NSString *toPort;

@property (strong, nonatomic) Class inferredType;

@end
