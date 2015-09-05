//
//  DFAggregatorOperation.h

//
//  Created by Sinha, Gyanendra on 6/23/14.

//

#import "DFReactiveOperation.h"

@interface DFAggregatorOperation : DFReactiveOperation

@property (strong, nonatomic) id input;

@property (readonly, nonatomic) NSArray *output;

+ (instancetype)aggregator;

@end
