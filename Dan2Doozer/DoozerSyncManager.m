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
#import "AddItemsToServer.h"
#import "UpdateItemsOnServer.h"
#import "DeleteItemFromServer.h"

//NSFetchedResultsController *_fetchedResultsController;
//NSMutableArray *_itemsArray;


@implementation DoozerSyncManager

+(void)syncWithServer :(NSManagedObjectContext *)passOnContext{
    
NSString *fbAccessToken = [[FBSDKAccessToken currentAccessToken] tokenString];
NSString *startOfURL = @"http://warm-atoll-6588.herokuapp.com/api/login/";
NSString *targetURL = [NSString stringWithFormat:@"%@%@", startOfURL, fbAccessToken];
    
AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
[manager GET:targetURL parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
NSString * sessionID = [responseObject objectForKey:@"sessionId"];
[[NSUserDefaults standardUserDefaults] setObject:sessionID forKey:@"UserLoginIdSession"];
[[NSUserDefaults standardUserDefaults] synchronize];
    
    GetItemsFromDoozer *foo = [[GetItemsFromDoozer alloc] init];
    [foo getItemsOnServer:^(NSMutableArray * itemsBigArray) {
        [self copyFromServer :passOnContext :itemsBigArray];
        
        NSMutableArray *newArrayOfListsToAdd = [[NSUserDefaults standardUserDefaults] valueForKey:@"listsToAdd"];
        NSLog(@"lists to add to server = %@", newArrayOfListsToAdd);
        NSMutableArray *newArrayOfItemsToAdd = [[NSUserDefaults standardUserDefaults] valueForKey:@"itemsToAdd"];
        NSLog(@"items to add to server = %@", newArrayOfItemsToAdd);
        NSMutableArray *itemsToUpdate = [[NSUserDefaults standardUserDefaults] valueForKey:@"itemsToUpdate"];
        NSLog(@"items to update on the server = %@", itemsToUpdate);
        NSMutableArray *itemsToDelete = [[NSUserDefaults standardUserDefaults] valueForKey:@"itemsToDelete"];
        NSLog(@"items to delete from server = %@", itemsToDelete);
        
        AddItemsToServer *moo = [[AddItemsToServer alloc] init];
        [moo addItemsToServer:newArrayOfListsToAdd :passOnContext :^(int handler) {
        
            //NSLog(@"here's the completion handler variable = %d", handler);
            //NSLog(@"add lists successfully returned");
            
            AddItemsToServer *cluck = [[AddItemsToServer alloc] init];
            [cluck addItemsToServer:newArrayOfItemsToAdd :passOnContext :^(int handler){
                
                //NSLog(@"add items successfully returned");
                UpdateItemsOnServer *baah = [[UpdateItemsOnServer alloc] init];
                [baah updateItemsOnServer:itemsToUpdate :passOnContext :^(int handler){
                    
                    //NSLog(@"update items successfully returned");
                    DeleteItemFromServer *meow = [[DeleteItemFromServer alloc] init];
                    [meow deleteItemFromServer:itemsToDelete :^(int handler){
                        
                        //NSLog(@"delete items successfully returned");
                        NSTimeInterval secondsSinceUnixEpoch = [[NSDate date]timeIntervalSince1970];
                        int secondsEpochInt = secondsSinceUnixEpoch;
                        NSNumber *secondsEpoch = [NSNumber numberWithInt:secondsEpochInt];
                        [[NSUserDefaults standardUserDefaults] setObject:secondsEpoch forKey:@"LastSuccessfulSync"];
                        [[NSUserDefaults standardUserDefaults] synchronize];
                        
                    }];
                    
                }];
                
            }];
            
        }];
        
    }];
        
        
} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
    NSLog(@"Error: %@", error);
}];
    
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
        
        NSMutableArray *itemsToDelete = [[NSUserDefaults standardUserDefaults] valueForKey:@"itemsToDelete"];
        NSString *idOfServerItem = [eachArrayElement objectForKey:@"id"];
        BOOL inDeleteQueue = NO;
        for (id eachItemInArray in itemsToDelete) {
            if ([eachItemInArray isEqualToString:idOfServerItem]){
                inDeleteQueue = YES;
            }
        }
        
        if (length == 0 && inDeleteQueue == NO){
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
            if (newItem.notes == nil) {
                newItem.notes = @" ";
            }
            
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
    
    
    NSNumber *launchCount = [[NSUserDefaults standardUserDefaults] valueForKey:@"NumberOfLaunches"];
    if ([launchCount intValue] == 0) {
        launchCount = [NSNumber numberWithInt:1];
        [[NSUserDefaults standardUserDefaults] setObject:launchCount forKey:@"NumberOfLaunches"];
    }
    
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
