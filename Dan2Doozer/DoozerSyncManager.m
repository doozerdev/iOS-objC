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
    GetItemsFromDoozer *foo = [[GetItemsFromDoozer alloc] init];
    [foo getItemsOnServer:^(NSMutableArray * itemsBigArray) {
        [self copyFromServer :passOnContext :itemsBigArray];
        
        NSMutableArray *newArrayOfItemsToAdd = [[NSUserDefaults standardUserDefaults] valueForKey:@"itemsToAdd"];
        NSLog(@"items to add to server = %@", newArrayOfItemsToAdd);
        NSMutableArray *itemsToUpdate = [[NSUserDefaults standardUserDefaults] valueForKey:@"itemsToUpdate"];
        NSLog(@"items to update on the server = %@", itemsToUpdate);
        NSMutableArray *itemsToDelete = [[NSUserDefaults standardUserDefaults] valueForKey:@"itemsToDelete"];
        NSLog(@"items to delete from server = %@", itemsToDelete);

        
        for (NSString *eachArrayElement in newArrayOfItemsToAdd){
            [self addItemToServer:eachArrayElement :passOnContext];
        }
        
        for (NSString *eachArrayElement in itemsToUpdate){
            [self updateItemOnServer:eachArrayElement :passOnContext];
        }
        
        for (NSString *eachArrayElement in itemsToDelete){
            [self deleteItemFromServer:eachArrayElement];
        }
        
        NSTimeInterval secondsSinceUnixEpoch = [[NSDate date]timeIntervalSince1970];
        int secondsEpochInt = secondsSinceUnixEpoch;
        NSNumber *secondsEpoch = [NSNumber numberWithInt:secondsEpochInt];
        [[NSUserDefaults standardUserDefaults] setObject:secondsEpoch forKey:@"LastSuccessfulSync"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
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

+ (void)addItemToServer:(NSString *)itemIdToAdd :(NSManagedObjectContext *)passOnContext{
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"ItemRecord" inManagedObjectContext:passOnContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:entity];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"itemId == %@", itemIdToAdd];
    [fetchRequest setPredicate:predicate];
    
    NSError *firsterror = nil;
    NSArray *results = [passOnContext executeFetchRequest:fetchRequest error:&firsterror];
    Item *itemToAdd = [results objectAtIndex:0];
    
    NSString *currentSessionId = [[NSUserDefaults standardUserDefaults] valueForKey:@"UserLoginIdSession"];
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager.requestSerializer setValue:currentSessionId forHTTPHeaderField:@"sessionId"];
    NSDictionary *params = nil;
    if (itemToAdd.parent == NULL) {
        params = @{@"title": itemToAdd.title, @"parent": @""};
        
    }else{
        params = @{@"title": itemToAdd.title, @"parent": itemToAdd.parent, @"order": itemToAdd.order};
    }
    
    [manager POST:@"https://warm-atoll-6588.herokuapp.com/api/items" parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"JSON: %@", responseObject);
        
        NSDictionary *serverResponse = (NSDictionary *)responseObject;
        //NSString *previousTempId = itemToAdd.itemId;

        //NSString *newItemUpdatedAt = [serverResponse objectForKey:@"updated_at"];
        //itemToAdd.updated_at = newItemUpdatedAt;
        
        
        NSString *newItemId = [serverResponse objectForKey:@"id"];
        itemToAdd.itemId = newItemId;
        
        if (itemToAdd.parent == nil) {
            NSEntityDescription *entity2 = [NSEntityDescription entityForName:@"ItemRecord" inManagedObjectContext:passOnContext];
            NSFetchRequest *fetchRequest2 = [[NSFetchRequest alloc] init];
            [fetchRequest2 setEntity:entity2];
            NSPredicate *predicate2 = [NSPredicate predicateWithFormat:@"parent == %@", itemIdToAdd];
            [fetchRequest2 setPredicate:predicate2];
            
            NSError *firsterror2 = nil;
            NSArray *results2 = [passOnContext executeFetchRequest:fetchRequest2 error:&firsterror2];
    
            for (id eachChild in results2){
                Item *childToModifyParent = eachChild;
                childToModifyParent.parent = newItemId;
            }
            
        }
        
        // Save the context.
        NSError *error = nil;
        if (![passOnContext save:&error]) {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
        
        NSMutableArray *newItemsToAdd = [[[NSUserDefaults standardUserDefaults] valueForKey:@"itemsToAdd"]mutableCopy];
        
        NSMutableArray *newItemsToAddCopy =[[NSMutableArray alloc]init];
       
        for (NSString * arrayElement in newItemsToAdd) {
            if ([arrayElement isEqualToString:itemIdToAdd]){
          
            }else{
            [newItemsToAddCopy addObject:arrayElement];
            }
        }
        
        [[NSUserDefaults standardUserDefaults] setObject:newItemsToAddCopy forKey:@"itemsToAdd"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
    
}


+ (void)updateItemOnServer:(NSString *)itemIdToUpdate :(NSManagedObjectContext *)passOnContext{
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"ItemRecord" inManagedObjectContext:passOnContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:entity];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"itemId == %@", itemIdToUpdate];
    [fetchRequest setPredicate:predicate];
    
    NSError *firsterror = nil;
    NSArray *results = [passOnContext executeFetchRequest:fetchRequest error:&firsterror];
    Item *itemToUpdate = [results objectAtIndex:0];
    
    NSString *currentSessionId = [[NSUserDefaults standardUserDefaults] valueForKey:@"UserLoginIdSession"];
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager.requestSerializer setValue:currentSessionId forHTTPHeaderField:@"sessionId"];

    NSDictionary *params = nil;
    
    if (itemToUpdate.archive == NULL) {
        params = @{
                    @"title": itemToUpdate.title,
                    @"order": itemToUpdate.order,
                    @"parent": itemToUpdate.parent,
                    @"notes": itemToUpdate.notes,
                    @"done": [NSNumber numberWithBool: itemToUpdate.done.boolValue],
                    //@"duedate": itemToUpdate.duedate
                    };
    }else{
        params = @{
                    @"archive": itemToUpdate.archive,
                    };
    }
    NSString *urlBase = [NSString stringWithFormat:@"https://warm-atoll-6588.herokuapp.com/api/items/%@", itemToUpdate.itemId];
    
    [manager PUT:urlBase parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"JSON: %@", responseObject);
        
        //NSDictionary *serverResponse = (NSDictionary *)responseObject;
        //NSString *previousTempId = itemToAdd.itemId;
        
        //NSString *newItemUpdatedAt = [serverResponse objectForKey:@"updated_at"];
        //itemToAdd.updated_at = newItemUpdatedAt;
        
        
        //NSString *newItemId = [serverResponse objectForKey:@"id"];
        //itemToUpdate.itemId = newItemId;
        
        // Save the context.
        NSError *error = nil;
        if (![passOnContext save:&error]) {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
        
        NSMutableArray *itemsToUpdate = [[[NSUserDefaults standardUserDefaults] valueForKey:@"itemsToUpdate"]mutableCopy];
        
        NSMutableArray *itemsToUpdateCopy =[[NSMutableArray alloc]init];
        
        for (NSString * arrayElement in itemsToUpdate) {
            if ([arrayElement isEqualToString:itemIdToUpdate]){
                
            }else{
                [itemsToUpdateCopy addObject:arrayElement];
            }
        }
        
        [[NSUserDefaults standardUserDefaults] setObject:itemsToUpdateCopy forKey:@"itemsToUpdate"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
    
}

+ (void)deleteItemFromServer:(NSString *)itemIdToDelete{
    
    NSString *currentSessionId = [[NSUserDefaults standardUserDefaults] valueForKey:@"UserLoginIdSession"];
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager.requestSerializer setValue:currentSessionId forHTTPHeaderField:@"sessionId"];
    
    NSString *URL = [NSString stringWithFormat:@"https://warm-atoll-6588.herokuapp.com/api/items/%@/archive", itemIdToDelete];
    
    [manager DELETE:URL parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"JSON: %@", responseObject);
        
        NSMutableArray *itemsToDelete = [[[NSUserDefaults standardUserDefaults] valueForKey:@"itemsToDelete"]mutableCopy];
        
        NSMutableArray *itemsToDeleteCopy =[[NSMutableArray alloc]init];
        
        for (NSString * arrayElement in itemsToDelete) {
            if ([arrayElement isEqualToString:itemIdToDelete]){

            }else{
                [itemsToDeleteCopy addObject:arrayElement];
            }
        }
        [[NSUserDefaults standardUserDefaults] setObject:itemsToDeleteCopy forKey:@"itemsToDelete"];
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
