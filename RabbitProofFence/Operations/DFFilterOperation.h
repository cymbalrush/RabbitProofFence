//
//  DFFilterOperation.h

//
//  Created by Sinha, Gyanendra on 6/23/14.

//

#import "DFReactiveOperation.h"

@interface DFFilterOperation : DFReactiveOperation

@property (strong, nonatomic) id input;

- (instancetype)initWithFilterBlock:(BOOL (^)(id input))filterBlock;

@end
