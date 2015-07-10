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
#import "ColorHelper.h"
#import "AppDelegate.h"

//NSFetchedResultsController *_fetchedResultsController;
//NSMutableArray *_itemsArray;


@implementation DoozerSyncManager


+(void)syncWithServer{

//login to Doozer if needed
    
    double currentTime = [[NSDate date] timeIntervalSince1970];
    NSNumber *lastDoozerAuth = [[NSUserDefaults standardUserDefaults] valueForKey:@"lastDoozerAuth"];
    
    NSLog(@"lastAuth %@ and cuurent time is %f, diff of %f", lastDoozerAuth, currentTime, currentTime-lastDoozerAuth.floatValue);
    
    NSString *currentSessionId = [[NSUserDefaults standardUserDefaults] valueForKey:@"UserLoginIdSession"];

    
    if ((currentTime - lastDoozerAuth.intValue) > 23*60*60 || currentSessionId == nil) {
        NSLog(@"needing to log in again....");
        
        NSString *fbAccessToken = [[FBSDKAccessToken currentAccessToken] tokenString];
        NSString *targetURL = [NSString stringWithFormat:@"http://warm-atoll-6588.herokuapp.com/api/login/%@", fbAccessToken];
        
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        [manager GET:targetURL parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
            
            NSString * sessionID = [responseObject objectForKey:@"sessionId"];
            [[NSUserDefaults standardUserDefaults] setObject:sessionID forKey:@"UserLoginIdSession"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            NSLog(@"returning message from login operation");
            
            [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithDouble:currentTime] forKey:@"lastDoozerAuth"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            
            [self performSyncSteps];
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Error: %@", error);
        }];
    }else{
        NSLog(@"syncing without needing new doozer login---------------");

        [self performSyncSteps];
        
    }
    
}


+(void)performSyncSteps{
    
    AppDelegate* appDelegate = [AppDelegate sharedAppDelegate];
    NSManagedObjectContext* context = appDelegate.managedObjectContext;
    
    GetItemsFromDoozer *foo = [[GetItemsFromDoozer alloc] init];
    NSLog(@"launching the GET ITEMS FROM DOOZER operatrion");
    [foo getItemsOnServer:^(NSMutableArray * itemsBigArray) {
        [self copyFromServer :itemsBigArray];
        
        NSMutableArray *newArrayOfListsToAdd = [[NSUserDefaults standardUserDefaults] valueForKey:@"listsToAdd"];
        //NSLog(@"lists to add to server = %@", newArrayOfListsToAdd);
        NSMutableArray *newArrayOfItemsToAdd = [[NSUserDefaults standardUserDefaults] valueForKey:@"itemsToAdd"];
        //NSLog(@"items to add to server = %@", newArrayOfItemsToAdd);
        NSMutableArray *itemsToUpdate = [[NSUserDefaults standardUserDefaults] valueForKey:@"itemsToUpdate"];
        //NSLog(@"items to update on the server = %@", itemsToUpdate);
        NSMutableArray *itemsToDelete = [[NSUserDefaults standardUserDefaults] valueForKey:@"itemsToDelete"];
        //NSLog(@"items to delete from server = %@", itemsToDelete);
        
        AddItemsToServer *moo = [[AddItemsToServer alloc] init];
        [moo addItemsToServer:newArrayOfListsToAdd :context :^(int handler) {
            
            //NSLog(@"here's the completion handler variable = %d", handler);
            //NSLog(@"add lists successfully returned");
            
            AddItemsToServer *cluck = [[AddItemsToServer alloc] init];
            [cluck addItemsToServer:newArrayOfItemsToAdd :context :^(int handler){
                
                //NSLog(@"add items successfully returned");
                UpdateItemsOnServer *baah = [[UpdateItemsOnServer alloc] init];
                [baah updateItemsOnServer:itemsToUpdate :context :^(int handler){
                    
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

    
}



+(void)copyFromServer :(NSMutableArray *)inputArray{
    
    AppDelegate* appDelegate = [AppDelegate sharedAppDelegate];
    NSManagedObjectContext* context = appDelegate.managedObjectContext;

    //look at each item that comes back from the server and see if we want to keep it
    for (id eachArrayElement in inputArray) {
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"ItemRecord" inManagedObjectContext:context];
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        [fetchRequest setEntity:entity];
        
        //pull anything from CoreData that has a matching item ID
        NSString *itemId = [eachArrayElement objectForKey:@"id"];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"itemId == %@", itemId];
        [fetchRequest setPredicate:predicate];
        NSError *firsterror = nil;
        NSArray *results = [context executeFetchRequest:fetchRequest error:&firsterror];
        NSLog(@"results = %@", results);
        NSUInteger length = [results count];
        NSLog(@"length = %lu", (unsigned long)length);
        
        NSMutableArray *itemsToDelete = [[NSUserDefaults standardUserDefaults] valueForKey:@"itemsToDelete"];
        NSString *idOfServerItem = [eachArrayElement objectForKey:@"id"];
        BOOL inDeleteQueue = NO;
        for (id eachItemInArray in itemsToDelete) {
            if ([eachItemInArray isEqualToString:idOfServerItem]){
                inDeleteQueue = YES;
            }
        }
        
        /*
         
         TODO - fix this
         
        NSString *archiveValue = [eachArrayElement objectForKey:@"archive"];
        NSLog(@"archive value = %@", archiveValue);
        
        if ([archiveValue isEqualToString:@"1"]) {
            NSLog(@"item ID %@ has been deleted", itemId);
        }
         */
        
        
        if (length > 0) {
            //keep server copy if item is NOT in update queue. keep app copy if item IS in update queue.
            
            NSMutableArray *itemsToUpdate = [[NSUserDefaults standardUserDefaults] valueForKey:@"itemsToUpdate"];
            NSLog(@"itemsToUpdate = %@", itemsToUpdate);
            BOOL inUpdateQueue = NO;
            
            for (id eachItemInArray in itemsToUpdate) {
                if ([eachItemInArray isEqualToString:idOfServerItem]){
                    inUpdateQueue = YES;
                }
            }
            
            if (!inUpdateQueue) {
                Item *existingItem = [results objectAtIndex:0];
                
                NSString *title = [eachArrayElement objectForKey:@"title"];
                existingItem.title = title;
                
                NSString *ordertemp = [eachArrayElement objectForKey:@"order"];
                existingItem.order = [NSNumber numberWithInt:ordertemp.intValue];
                
                NSString *colorTemp = [eachArrayElement objectForKey:@"color"];
                existingItem.color = colorTemp;
                
                NSNumber *donetemp = [eachArrayElement objectForKey:@"done"];
                existingItem.done = donetemp;
                
                NSString *notes = [eachArrayElement objectForKey:@"notes"];
                existingItem.notes = notes;
                if (existingItem.notes == nil) {
                    existingItem.notes = @" ";
                }
                
                NSString *duedateString = [eachArrayElement objectForKey:@"duedate"];
                NSDateFormatter* df = [[NSDateFormatter alloc]init];
                [df setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZ"];
                NSDate* duedate = [df dateFromString:duedateString];
                existingItem.duedate = duedate;
                
                NSError *error = nil;
                if (![context save:&error]) {
                    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
                    abort();
                }
            }
        }
        
        if (length == 0 && !inDeleteQueue){
            Item *newItem = [[Item alloc] initWithEntity:entity insertIntoManagedObjectContext:context];
            
            //NSString *archiveValue = [eachArrayElement objectForKey:@"archive"];
            //NSLog(@"archive value is = %@", archiveValue);
            
            NSString *title = [eachArrayElement objectForKey:@"title"];
            newItem.title = title;
            NSLog(@"creating an item of title %@", newItem.title);
            
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
            
            NSString *typeTemp = [eachArrayElement objectForKey:@"type"];
            newItem.type = typeTemp;
            
            if (!newItem.parent) {
                NSString *colorTemp = [eachArrayElement objectForKey:@"color"];
                if (colorTemp.length < 1) {
                    NSNumber *colorPicker = [[NSUserDefaults standardUserDefaults] valueForKey:@"colorPicker"];
                    
                    colorTemp = [ColorHelper returnUIColorString:colorPicker.intValue];
                    int newColorPickerValue = 1 + colorPicker.intValue;
                    if (newColorPickerValue > 4) {
                        newColorPickerValue = 0;
                    }
                    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:newColorPickerValue] forKey:@"colorPicker"];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                }
                newItem.color = colorTemp;

            }
        
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
            if (![context save:&error]) {
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
