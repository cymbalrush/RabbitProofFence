//
//  DFAndOperation.h

//
//  Created by Sinha, Gyanendra on 6/23/14.

//

#import "DFReactiveOperation.h"

@interface DFAndOperation : DFReactiveOperation 

@property (readonly, nonatomic) NSArray *output;

+ (instancetype)andOperation:(NSArray *)ports;

- (instancetype)initWithPorts:(NSArray *)ports;

@end
