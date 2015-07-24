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

+(NSInteger)findNumberOfDueItems{
    
    AppDelegate* appDelegate = [AppDelegate sharedAppDelegate];
    NSManagedObjectContext* context = appDelegate.managedObjectContext;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"ItemRecord" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    
    [fetchRequest setFetchBatchSize:20];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"parent == %@", nil];
    [fetchRequest setPredicate:predicate];
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"order" ascending:YES];
    NSArray *sortDescriptors = @[sortDescriptor];
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:context sectionNameKeyPath:nil cacheName:@"Master4"];
    [NSFetchedResultsController deleteCacheWithName:@"Master4"];
    
    NSError *error = nil;
    if (![aFetchedResultsController performFetch:&error]) {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    NSArray *items = aFetchedResultsController.fetchedObjects;
    
    NSMutableArray *activeItems = [[NSMutableArray alloc]init];
    
    for (Item *eachParentList in items) {
        
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"ItemRecord" inManagedObjectContext:context];
        [fetchRequest setEntity:entity];
        
        [fetchRequest setFetchBatchSize:20];
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"parent == %@", eachParentList.itemId];
        [fetchRequest setPredicate:predicate];
        
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"order" ascending:YES];
        NSArray *sortDescriptors = @[sortDescriptor];
        [fetchRequest setSortDescriptors:sortDescriptors];
        
        NSFetchedResultsController *bFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:context sectionNameKeyPath:nil cacheName:@"Master5"];
        [NSFetchedResultsController deleteCacheWithName:@"Master5"];
        
        NSError *error = nil;
        if (![bFetchedResultsController performFetch:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
        
        [activeItems addObjectsFromArray:bFetchedResultsController.fetchedObjects];
        
    }

    NSDateFormatter *df = [[NSDateFormatter alloc]init];
    [df setDateFormat:@"yyyyMMdd"];
    NSString *currentDateString = [df stringFromDate:[NSDate date]];
    NSInteger count = 0;
    
    for (Item *eachItem in activeItems){
        NSLog(@"item name is == %@, archive value is == %@", eachItem.title, eachItem.archive);
        if (eachItem.done.intValue == 0) {
            NSString *dueDateString = [df stringFromDate:eachItem.duedate];
            if (dueDateString.intValue > 0 && dueDateString.intValue <= currentDateString.intValue) {
                count += 1;
            }
        }
    }
    
    return count;

}

@end
