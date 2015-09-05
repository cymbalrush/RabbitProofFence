//
//  DFMapOperation.h

//
//  Created by Sinha, Gyanendra on 6/23/14.

//

#import "DFReactiveOperation.h"

@interface DFMapOperation : DFReactiveOperation

- (instancetype)initWithMapBlock:(id)mapBlock ports:(NSArray *)ports;

@end
