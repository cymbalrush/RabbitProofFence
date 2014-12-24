//
//  DFCoreDataOperation.h
//  vf-hollywood
//
//  Created by Sinha, Gyanendra on 6/23/14.
//  Copyright (c) 2014 Conde Nast. All rights reserved.
//

#import "DFOperation.h"
#import <CoreData/CoreData.h>

@interface DFCoreDataOperation : DFOperation

@property (strong, nonatomic) NSManagedObjectContext *context;

@end
