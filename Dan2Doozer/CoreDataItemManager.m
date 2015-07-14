//
//  CoreDataItemManager.m
//  Doozer
//
//  Created by Daniel Apone on 5/29/15.
//  Copyright (c) 2015 Daniel Apone. All rights reserved.
//

#import "CoreDataItemManager.h"
#import "AppDelegate.h"
#import "UpdateItemsOnServer.h"

NSFetchedResultsController *_fetchedResultsController;

@implementation CoreDataItemManager

+(int)findNumberOfUncompletedChildren :(NSString *)parent{
    
    AppDelegate* appDelegate = [AppDelegate sharedAppDelegate];
    NSManagedObjectContext* context = appDelegate.managedObjectContext;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"ItemRecord" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"order" ascending:YES];
    NSArray *sortDescriptors = @[sortDescriptor];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:context sectionNameKeyPath:nil cacheName:@"CoreData"];
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
    
    for (Item *item in fetchedObjects)
    {
        if ([item.parent isEqualToString:parent]) {
            
            if (item.done.intValue == 0  && ![item.type isEqualToString:@"completed_header"]){
                numberOfUncompletedChildren+=1;
            }
        }
    }
    return numberOfUncompletedChildren;
}

+(void)rebalanceItemOrderValues :(NSArray *)arrayOfItems{
    int orderStepValue = 1073741824/[arrayOfItems count];
    //int orderStepValue = 32;
    int itemOrderMultiplier = 1;
    for (Item *eachItem in arrayOfItems) {
        NSLog(@"%@ order is %@", eachItem.title, eachItem.order);
        eachItem.order = [NSNumber numberWithInt:itemOrderMultiplier*orderStepValue];
        NSLog(@"%@ NEW order is %@", eachItem.title, eachItem.order);
        [UpdateItemsOnServer updateThisItem:eachItem];
        itemOrderMultiplier += 1;
    }
    
}

@end
