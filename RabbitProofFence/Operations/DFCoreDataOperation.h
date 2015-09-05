//
//  DFCoreDataOperation.h

//
//  Created by Sinha, Gyanendra on 6/23/14.

//

#import "DFOperation.h"
#import <CoreData/CoreData.h>

@interface DFCoreDataOperation : DFOperation

@property (strong, nonatomic) NSManagedObjectContext *context;

@end
