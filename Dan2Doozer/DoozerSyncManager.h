//
//  DoozerSyncManager.h
//  Doozer
//
//  Created by Daniel Apone on 5/30/15.
//  Copyright (c) 2015 Daniel Apone. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/Coredata.h>

@interface DoozerSyncManager : NSObject 


+ (void)syncWithServer:(NSManagedObjectContext *)passOnContext;

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
//@property (strong, nonatomic) NSMutableArray * itemsArray;



@end