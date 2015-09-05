//
//  DFConnectorOperation.h

//
//  Created by Sinha, Gyanendra on 7/2/14.

//

#import "DFOperation.h"
#import "StreamOperation.h"

#define DFConnector(object, objProperty)\
[DFConnectorOperation connectorFromObject:object property:objProperty]

@interface DFConnectorOperation : DFOperation <StreamOperation>

@property (nonatomic, readonly) NSObject *object;

@property (nonatomic, readonly) NSString *property;

@property (nonatomic, assign) BOOL useCurrentValue;

+ (instancetype)connectorFromObject:(NSObject *)object property:(NSString *)property;

- (instancetype)initWithObject:(NSObject *)object property:(NSString *)property;

@end
