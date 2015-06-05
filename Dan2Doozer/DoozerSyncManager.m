//
//  DoozerSyncManager.m
//  Doozer
//
//  Created by Daniel Apone on 5/30/15.
//  Copyright (c) 2015 Daniel Apone. All rights reserved.
//

#import "DoozerSyncManager.h"
#import "AFNetworking.h"
#import "Item.h"
#import "GetItemsFromDoozer.h"

//NSFetchedResultsController *_fetchedResultsController;
NSMutableArray *_itemsArray;


@implementation DoozerSyncManager

+(void)syncWithServer :(NSManagedObjectContext *)passOnContext{
    //[self getItemsFromServer:passOnContext];
    NSLog(@"here's the items");
    GetItemsFromDoozer *foo = [[GetItemsFromDoozer alloc] init];
    [foo getItemsOnServer:^(NSMutableArray * itemsBigArray) {
        NSLog(@"here's the items array from Completion handler = %@", itemsBigArray);
        
        [self copyFromServer :passOnContext :itemsBigArray];
        
        NSDate * now = [NSDate date];
        [[NSUserDefaults standardUserDefaults] setObject:now forKey:@"LastSuccessfulSync"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        
        NSMutableArray *newArrayOfItemsToUpdate = [[NSUserDefaults standardUserDefaults] valueForKey:@"itemsToUpdate"];
        
        NSLog(@"here's the items to update array = %@", newArrayOfItemsToUpdate);
        
        for (NSString *eachArrayElement in newArrayOfItemsToUpdate){
            [self addItemToServer:eachArrayElement :passOnContext];
        }
        
        
        
    }];
    NSLog(@"after the handler fires");

}

+(void)copyFromServer:(NSManagedObjectContext *) passOnContext :(NSMutableArray *)inputArray{
    
    for (id eachArrayElement in inputArray) {
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"ItemRecord" inManagedObjectContext:passOnContext];
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        [fetchRequest setEntity:entity];
        NSString *itemId = [eachArrayElement objectForKey:@"id"];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"itemId == %@", itemId];
        [fetchRequest setPredicate:predicate];
        
        NSError *firsterror = nil;
        NSArray *results = [passOnContext executeFetchRequest:fetchRequest error:&firsterror];
        NSUInteger length = [results count];
        NSLog(@"nsuinteger lenght of array = %lu", length);
        
        if (length == 0){
            NSLog(@"seemingly adding a new item");
            
            Item *newItem = [[Item alloc] initWithEntity:entity insertIntoManagedObjectContext:passOnContext];
            
            NSString *title = [eachArrayElement objectForKey:@"title"];
            newItem.title = title;
            
            NSString *ordertemp = [eachArrayElement objectForKey:@"order"];
            NSInteger ordertempInt = [ordertemp integerValue];
            NSNumber *order = [NSNumber numberWithInteger:ordertempInt];
            newItem.order = order;
            
            NSString *parenttemp = [eachArrayElement objectForKey:@"parent"];
            if (parenttemp.length < 3){
                newItem.parent = nil;
            }else{
                newItem.parent = parenttemp;
            }
            
            NSString *idtemp = [eachArrayElement objectForKey:@"id"];
            newItem.itemId = idtemp;
            
            int r = arc4random_uniform(5);
            newItem.list_color = [NSNumber numberWithInt:r];
            
            NSNumber *donetemp = [eachArrayElement objectForKey:@"done"];
            newItem.done = donetemp;
            
            NSString *notes = [eachArrayElement objectForKey:@"notes"];
            newItem.notes = notes;
            
            NSString *duedateString = [eachArrayElement objectForKey:@"duedate"];
            NSDateFormatter* df = [[NSDateFormatter alloc]init];
            [df setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZ"];
            NSDate* duedate = [df dateFromString:duedateString];
            newItem.duedate = duedate;
            
            NSNumber *children_undone = [eachArrayElement objectForKey:@"children_undone"];
            newItem.children_undone = children_undone;
            
            // Save the context.
            NSError *error = nil;
            if (![passOnContext save:&error]) {
                NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
                abort();
            }
        
        }
    }
}

+ (void)addItemToServer:(NSString *)itemIdToAdd :(NSManagedObjectContext *)passOnContext{
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"ItemRecord" inManagedObjectContext:passOnContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:entity];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"itemId == %@", itemIdToAdd];
    [fetchRequest setPredicate:predicate];
    
    NSError *firsterror = nil;
    NSArray *results = [passOnContext executeFetchRequest:fetchRequest error:&firsterror];
    NSLog(@"here's the array of items = %@", results);
    Item *itemToAdd = [results objectAtIndex:0];
    
    NSString *currentSessionId = [[NSUserDefaults standardUserDefaults] valueForKey:@"UserLoginIdSession"];
    NSLog(@"current session ID = %@", currentSessionId);
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager.requestSerializer setValue:currentSessionId forHTTPHeaderField:@"sessionId"];
    
    
    NSDictionary *params = @{@"title": itemToAdd.title, @"parent": itemToAdd.parent};
    [manager POST:@"https://warm-atoll-6588.herokuapp.com/api/items" parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"JSON: %@", responseObject);
        
        NSDictionary *serverResponse = (NSDictionary *)responseObject;
        //NSString *previousTempId = itemToAdd.itemId;

        //NSString *newItemUpdatedAt = [serverResponse objectForKey:@"updated_at"];
        //itemToAdd.updated_at = newItemUpdatedAt;
        
        
        NSString *newItemId = [serverResponse objectForKey:@"id"];
        itemToAdd.itemId = newItemId;
        
        // Save the context.
        NSError *error = nil;
        if (![passOnContext save:&error]) {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
        
        NSMutableArray *newItemsToUpdate = [[[NSUserDefaults standardUserDefaults] valueForKey:@"itemsToUpdate"]mutableCopy];
        
        NSMutableArray *newItemsToUpdateCopy =[[NSMutableArray alloc]init];
       
        for (NSString * arrayElement in newItemsToUpdate) {
            if ([arrayElement isEqualToString:itemIdToAdd]){
          
            }else{
            [newItemsToUpdateCopy addObject:arrayElement];
            }
        }
        
        [[NSUserDefaults standardUserDefaults] setObject:newItemsToUpdateCopy forKey:@"itemsToUpdate"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    
     
        
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
    
}



- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"ItemRecord" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"order" ascending:YES];
    NSArray *sortDescriptors = @[sortDescriptor];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:@"Detail"];
    //aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;
    [NSFetchedResultsController deleteCacheWithName:@"Detail"];
    
    
    NSError *error = nil;
    if (![self.fetchedResultsController performFetch:&error]) {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _fetchedResultsController;
}




@end
