//
//  CoreDataItemManager.m
//  Doozer
//
//  Created by Daniel Apone on 5/29/15.
//  Copyright (c) 2015 Daniel Apone. All rights reserved.
//

#import "CoreDataItemManager.h"
#import "AppDelegate.h"

NSFetchedResultsController *_fetchedResultsController;

@implementation CoreDataItemManager

+(int)findNumberOfUncompletedChildren :(NSString *)parent :(NSManagedObjectContext *)managedObjectContext{
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"ItemRecord" inManagedObjectContext:managedObjectContext];
    [fetchRequest setEntity:entity];
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"order" ascending:YES];
    NSArray *sortDescriptors = @[sortDescriptor];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:managedObjectContext sectionNameKeyPath:nil cacheName:@"CoreData"];
    //aFetchedResultsController.delegate = self;
    _fetchedResultsController = aFetchedResultsController;
    [NSFetchedResultsController deleteCacheWithName:@"CoreData"];
    
    NSError *error = nil;
    if (![_fetchedResultsController performFetch:&error]) {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    NSArray *fetchedObjects = [_fetchedResultsController fetchedObjects];
    int numberOfUncompletedChildren = 0;
    
    for (id item in fetchedObjects)
    {
        NSString *test = [item valueForKey:@"parent"];
        if ([test isEqualToString:parent]) {
            
            NSNumber *checkUndone = [item valueForKey:@"done"];
            if ([checkUndone intValue] == 0){
                numberOfUncompletedChildren+=1;
            }
        }
    }
    return numberOfUncompletedChildren;
}


@end
