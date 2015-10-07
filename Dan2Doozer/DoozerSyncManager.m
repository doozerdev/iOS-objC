//
//  DoozerSyncManager.m
//  Doozer
//
//  Created by Daniel Apone on 5/30/15.
//  Copyright (c) 2015 Daniel Apone. All rights reserved.
//

#import "DoozerSyncManager.h"
#import "AFNetworking.h"
#import "GetItemsFromDoozer.h"
#import "AddItemsToServer.h"
#import "UpdateItemsOnServer.h"
#import "DeleteItemFromServer.h"
#import "ColorHelper.h"
#import "AppDelegate.h"
#import "LoginViewController.h"
//#import "lelib.h"
#import "Constants.h"
#import "Solution.h"


BOOL _syncOpActive; //if server is slow - don't request another sync op if one is active
int _syncTryCount;
double _lastSyncRequest;


@implementation DoozerSyncManager


+(void)syncWithServer{
    
    //NSLog(@"---------FB access token ======= %@", [FBSDKAccessToken currentAccessToken]);
    
    if ([FBSDKAccessToken currentAccessToken]) {
        //NSLog(@"valid token fB");

        double currentSyncRequest = [[NSDate date] timeIntervalSince1970];
        
        NSLog(@"diff in time sync requests is %f", currentSyncRequest - _lastSyncRequest);
        
        if (currentSyncRequest - _lastSyncRequest > 3) {
            
            _lastSyncRequest = currentSyncRequest;

            //login to Doozer if needed
            if(_syncOpActive){
                NSLog(@"sync op active! no additional sync this time");
                _syncTryCount += 1;

                if (_syncTryCount > 3) {
                    _syncOpActive = NO;
                    _syncTryCount = 0;
                    NSLog(@"reseting synctrycount and syncopactive");
                }
            }else{
                _syncTryCount = 0;
                _syncOpActive = YES;
                double currentTime = [[NSDate date] timeIntervalSince1970];
                NSNumber *lastDoozerAuth = [[NSUserDefaults standardUserDefaults] valueForKey:@"lastDoozerAuth"];
                
                //NSLog(@"lastAuth %@ and cuurent time is %f, diff of %f", lastDoozerAuth, currentTime, currentTime-lastDoozerAuth.floatValue);
                
                NSString *currentSessionId = [[NSUserDefaults standardUserDefaults] valueForKey:@"UserLoginIdSession"];

                
                if ((currentTime - lastDoozerAuth.intValue) > 23*60*60 || currentSessionId == nil) {
                    NSLog(@"Sync starts with LOGIN");
                    
                    [FBSDKAccessToken refreshCurrentAccessToken:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
                        
                        NSLog(@"************ Refreshed Access Token === %@", [FBSDKAccessToken currentAccessToken]);
                        NSString *fbAccessToken = [[FBSDKAccessToken currentAccessToken] tokenString];
                        AppDelegate* appDelegate = [AppDelegate sharedAppDelegate];
                        NSString *targetURL = [NSString stringWithFormat:@"%@login/%@", appDelegate.SERVER_URI ,fbAccessToken];
                        
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
                        
                    }];
                    

                }else{
                    NSLog(@"Sync WITHOUT login needed");

                    [self performSyncSteps];
                }
            }
        }
    }else{
        NSLog(@"no FB token - should direct back to login screen");
        
        
        /*
        LoginViewController *loginController = [[LoginViewController alloc]
                                                  init];
        loginController.delegate = self;
        
        //UINavigationController *navigationController = [[UINavigationController alloc]
                                                        //initWithRootViewController:loginController];
        [self presentViewController:loginController animated:YES completion: nil];
    */
    }
}


+(void)performSyncSteps{
    
    AppDelegate* appDelegate = [AppDelegate sharedAppDelegate];
    NSManagedObjectContext* context = appDelegate.managedObjectContext;
    
    GetItemsFromDoozer *foo = [[GetItemsFromDoozer alloc] init];
    //NSLog(@"launching the GET ITEMS FROM DOOZER operatrion");
    [foo getItemsOnServer:^(NSMutableArray * itemsBigArray) {
        
        NSLog(@"items from server ============= %@", itemsBigArray);
        
        id firstItem = nil;
        if ([itemsBigArray count] > 0) {
            firstItem = [itemsBigArray objectAtIndex:0];
        }
        if ([firstItem isKindOfClass:[NSString class]]) {
            NSLog(@"it's a string and the value is %@", firstItem);
            _syncOpActive = NO;
            
            [self performSelector:@selector(syncWithServer) withObject:nil afterDelay:3.5f];

        }else{
        
            [self copyFromServer :itemsBigArray];
            
            NSMutableArray *newArrayOfListsToAdd = [[NSUserDefaults standardUserDefaults] valueForKey:@"listsToAdd"];
            NSLog(@"lists to add to server = %@", newArrayOfListsToAdd);
            NSMutableArray *newArrayOfItemsToAdd = [[NSUserDefaults standardUserDefaults] valueForKey:@"itemsToAdd"];
            NSLog(@"items to add to server = %@", newArrayOfItemsToAdd);
            NSMutableArray *itemsToUpdate = [[NSUserDefaults standardUserDefaults] valueForKey:@"itemsToUpdate"];
            NSLog(@"items to update on the server = %@", itemsToUpdate);
            NSMutableArray *itemsToDelete = [[NSUserDefaults standardUserDefaults] valueForKey:@"itemsToDelete"];
            NSLog(@"items to delete from server = %@", itemsToDelete);
            
            //LELog* log = [LELog sharedInstance];
            //log.token = @"059ad121-e3f3-4a5e-88a4-07278ab04900";
            //[log log: [NSString stringWithFormat:@"Sync. Lists - %@, Items - %@, Updates - %@, Delete - %@, for user %@", newArrayOfListsToAdd, newArrayOfItemsToAdd, itemsToUpdate, itemsToDelete, [FBSDKProfile currentProfile].userID]];
            
            AddItemsToServer *moo = [[AddItemsToServer alloc] init];
            [moo addItemsToServer:newArrayOfListsToAdd :context :^(int handler) {
                
                if (handler == -1) {
                    _syncOpActive = NO;
                }else{
                
                    AddItemsToServer *cluck = [[AddItemsToServer alloc] init];
                    [cluck addItemsToServer:newArrayOfItemsToAdd :context :^(int handler){
                        
                        if (handler == -1) {
                            _syncOpActive = NO;

                        }else{
                        
                            //NSLog(@"add items successfully returned");
                            UpdateItemsOnServer *baah = [[UpdateItemsOnServer alloc] init];
                            [baah updateItemsOnServer:itemsToUpdate :context :^(int handler){
                                
                                if (handler == -1) {
                                    _syncOpActive = NO;

                                }else{
                                
                                    //NSLog(@"update items successfully returned");
                                    DeleteItemFromServer *meow = [[DeleteItemFromServer alloc] init];
                                    [meow deleteItemFromServer:itemsToDelete :^(int handler){
                                        
                                        if (handler != -1) {
                                            //NSLog(@"delete items successfully returned");
                                            NSTimeInterval secondsSinceUnixEpoch = [[NSDate date]timeIntervalSince1970];
                                            int secondsEpochInt = secondsSinceUnixEpoch;
                                            NSNumber *secondsEpoch = [NSNumber numberWithInt:secondsEpochInt];
                                            [[NSUserDefaults standardUserDefaults] setObject:secondsEpoch forKey:@"LastSuccessfulSync"];
                                            [[NSUserDefaults standardUserDefaults] synchronize];
                                            
                                            //LELog* log = [LELog sharedInstance];
                                            //log.token = @"059ad121-e3f3-4a5e-88a4-07278ab04900";
                                            //[log log: [NSString stringWithFormat:@"Sync succesful for user %@", [FBSDKProfile currentProfile].userID]];
                                            NSLog(@"sync op complete");
                                        }
                                        _syncOpActive = NO;

                                    }];
                                }
                            }];
                        }
                    }];
                }
            }];
        }
    }];
}



+(void)copyFromServer :(NSMutableArray *)inputArray{
    //NSLog(@"starting copy from server function");
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
        //NSLog(@"results = %@", results);
        NSUInteger length = [results count];
        //NSLog(@"does the server item match a local item = %lu", (unsigned long)length);
        
        NSMutableArray *itemsToDelete = [[NSUserDefaults standardUserDefaults] valueForKey:@"itemsToDelete"];
        NSString *idOfServerItem = [eachArrayElement objectForKey:@"id"];
        BOOL inDeleteQueue = NO;
        for (id eachItemInArray in itemsToDelete) {
            if ([eachItemInArray isEqualToString:idOfServerItem]){
                inDeleteQueue = YES;
            }
        }
        
        
        NSString *archiveValue = [eachArrayElement objectForKey:@"archive"];
        //NSLog(@"archive value = %@", archiveValue);
        
        int numnum = archiveValue.intValue;
        
        if (numnum == 1) {
            //NSLog(@"item ID %@ has been deleted, don't create a local item", itemId);
            
            if (length > 0) {
                
                Item *existingItem = [results objectAtIndex:0];
                
                [context deleteObject:existingItem];
                
                
                // Save the context.
                NSError *error = nil;
                if (![context save:&error]) {
                    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
                    abort();
                }
                
                
            }
        }else{
         
            if (length > 0) {
               //We actually want to keep the server or app copy of the item based on which was more recently updated.
            
                Item *existingItem = [results objectAtIndex:0];
                
                double local = [existingItem.updated_at timeIntervalSince1970];
                
                NSString *updatedAtString = [eachArrayElement objectForKey:@"updated_at"];
                NSDateFormatter* df2 = [[NSDateFormatter alloc]init];
                [df2 setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZ"];
                NSDate* updatedDate = [df2 dateFromString:updatedAtString];
                double server = [updatedDate timeIntervalSince1970];
                
                if (server > local) {
                    
                    existingItem.updated_at = updatedDate;
                    
                    NSString *title = [eachArrayElement objectForKey:@"title"];
                    existingItem.title = title;
                    
                    NSString *ordertemp = [eachArrayElement objectForKey:@"order"];
                    existingItem.order = [NSNumber numberWithInt:ordertemp.intValue];
                    
                    NSString *sol_count_temp = [eachArrayElement objectForKey:@"solutions_count"];
                    existingItem.solutions_count = [NSNumber numberWithInt:sol_count_temp.intValue];
                    
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
                    
                    NSNumber *solutionsCount = [eachArrayElement objectForKey:@"solutions_count"];
                    
                    NSLog(@"creating! %@ %@ %@", existingItem.title, existingItem.itemId, solutionsCount);
                    
                    
                    if (solutionsCount.intValue > 0) {
                        
                        [self getSolutions:existingItem];
                    }
                    
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
                
                NSString *sol_count_temp = [eachArrayElement objectForKey:@"solutions_count"];
                newItem.solutions_count = [NSNumber numberWithInt:sol_count_temp.intValue];
                
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
                
                NSString *updatedAtString = [eachArrayElement objectForKey:@"updated_at"];
                NSDateFormatter* df2 = [[NSDateFormatter alloc]init];
                [df2 setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZ"];
                NSDate* updatedDate = [df2 dateFromString:updatedAtString];
                newItem.updated_at = updatedDate;
                
                NSNumber *children_undone = [eachArrayElement objectForKey:@"children_undone"];
                newItem.children_undone = children_undone;
                
                
                ///////////////Solutions Fetching Here!!!!!!!!!!!!!
                
                
                NSNumber *solutionsCount = [eachArrayElement objectForKey:@"solutions_count"];
                
                NSLog(@"creating! %@ %@ %@", newItem.title, newItem.itemId, solutionsCount);
                
                
                if (solutionsCount.intValue > 0) {

                    [self getSolutions:newItem];
                }
                
                
                // Save the context.
                NSError *error = nil;
                if (![context save:&error]) {
                    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
                    abort();
                }
            }
        }
    }
    
    
    NSNumber *launchCount = [[NSUserDefaults standardUserDefaults] valueForKey:@"NumberOfLaunches"];
    if ([launchCount intValue] == 0) {
        launchCount = [NSNumber numberWithInt:1];
        [[NSUserDefaults standardUserDefaults] setObject:launchCount forKey:@"NumberOfLaunches"];
    }
    
    //NSLog(@"ending copy from server function");

}


+ (void)getSolutions:(Item *)item{
    
    AppDelegate* appDelegate = [AppDelegate sharedAppDelegate];
    NSManagedObjectContext* context = appDelegate.managedObjectContext;
    
    NSString * NewURL = [NSString stringWithFormat:@"%@items/%@/solutions", appDelegate.SERVER_URI, item.itemId];
    
    NSString *currentSessionId = [[NSUserDefaults standardUserDefaults] valueForKey:@"UserLoginIdSession"];
    
    AFHTTPRequestOperationManager *cats = [AFHTTPRequestOperationManager manager];
    
    [cats.requestSerializer setValue:currentSessionId forHTTPHeaderField:@"sessionId"];
    
    NSMutableArray *solutionsList = [[NSMutableArray alloc]init];
    
    [cats GET:NewURL parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSDictionary *jsonDict = (NSDictionary *) responseObject;
        NSArray * itemsArray = [jsonDict objectForKey:@"items"];
        //NSLog(@" heres' the server response =%@", itemsArray);
        
        
        for (id eachArrayElement in itemsArray) {
            NSEntityDescription *entity = [NSEntityDescription entityForName:@"SolutionRecord" inManagedObjectContext:context];
            Solution *newSolution = [[Solution alloc]initWithEntity:entity insertIntoManagedObjectContext:context];
            
            newSolution.sol_title = [eachArrayElement objectForKey:@"title"];
            newSolution.address = [eachArrayElement objectForKey:@"address"];
            newSolution.sol_description = [eachArrayElement objectForKey:@"description"];
            newSolution.expire_date = [eachArrayElement objectForKey:@"expireDate"];
            newSolution.sol_ID = [eachArrayElement objectForKey:@"id"];
            newSolution.img_link = [eachArrayElement objectForKey:@"img_link"];
            newSolution.link = [eachArrayElement objectForKey:@"link"];
            newSolution.notes = [eachArrayElement objectForKey:@"notes"];
            newSolution.open_hours = [eachArrayElement objectForKey:@"openHours"];
            newSolution.phone_number = [eachArrayElement objectForKey:@"phoneNumber"];
            newSolution.price = [eachArrayElement objectForKey:@"price"];
            newSolution.source = [eachArrayElement objectForKey:@"source"];
            newSolution.tags = [eachArrayElement objectForKey:@"tags"];
            
            NSString *assDateString = [eachArrayElement objectForKey:@"date_associated"];
            NSDateFormatter* df = [[NSDateFormatter alloc]init];
            [df setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZ"];
            NSDate* assDate = [df dateFromString:assDateString];
            newSolution.date_associated = assDate;
            
            [solutionsList addObject:newSolution.sol_ID];
            
            // Save the context.
            NSError *error = nil;
            if (![context save:&error]) {
                NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
                abort();
            }
            
        }
        
        
        item.solutions = [[solutionsList valueForKey:@"description"] componentsJoinedByString:@","];
        //NSLog(@"Solutions found!!! and then equal == %@", item.solutions);
        
        // Save the context.
        NSError *error = nil;
        if (![context save:&error]) {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
        
        
    }
      failure:^(AFHTTPRequestOperation *operation, NSError *error) {
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
