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

//NSFetchedResultsController *_fetchedResultsController;

@implementation DoozerSyncManager

+(void)syncWithServer :(NSManagedObjectContext *)passOnContext{
    
    NSMutableArray * itemsArray = [[NSMutableArray alloc] init];
    __block NSMutableArray * fetchedArray = [[NSMutableArray alloc] init];
    
    NSString *NewURL = @"http://warm-atoll-6588.herokuapp.com/api/items";
    
    NSString *currentSessionId = [[NSUserDefaults standardUserDefaults] valueForKey:@"UserLoginIdSession"];
    
    AFHTTPRequestOperationManager *cats = [AFHTTPRequestOperationManager manager];
    [cats.requestSerializer setValue:currentSessionId forHTTPHeaderField:@"sessionId"];
    
    [cats GET:NewURL parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSDictionary *jsonDict = (NSDictionary *) responseObject;
        fetchedArray = [jsonDict objectForKey:@"items"];
        
        [itemsArray addObjectsFromArray:fetchedArray];
        
        long numberOfLists = [fetchedArray count];
        int loopCount = 0;
        
        for (id eachArrayElement in fetchedArray) {
            loopCount += 1;
            //NSNumber *children = [eachArrayElement objectForKey:@"children_count"];
            NSString *itemId = [eachArrayElement objectForKey:@"id"];
        
            NSString *getChildrenURL = [NSString stringWithFormat:@"http://warm-atoll-6588.herokuapp.com/api/items/%@/children", itemId];
            AFHTTPRequestOperationManager *dogs = [AFHTTPRequestOperationManager manager];
            [dogs.requestSerializer setValue:currentSessionId forHTTPHeaderField:@"sessionId"];
            [dogs GET:getChildrenURL parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
                
                NSDictionary *jsonChildrenDict = (NSDictionary *) responseObject;
                NSArray * fetchedChildrenArray = [jsonChildrenDict objectForKey:@"items"];
                [itemsArray addObjectsFromArray:fetchedChildrenArray];
            
                NSLog(@"loopcount = %d and number of lists = %ld", loopCount, numberOfLists);
                if (loopCount == numberOfLists){
                    [self meshDataStores:passOnContext:itemsArray];
                    NSLog(@"print the whole array of items = %@", itemsArray);
                }
                    
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                NSLog(@"Error: %@", error);
            }];
        }
    }
      failure:^(AFHTTPRequestOperation *operation, NSError *error) {
          NSLog(@"Error: %@", error);
          
      }];
    
}

+(void)meshDataStores:(NSManagedObjectContext *) passOnContext :(NSMutableArray *)inputArray{
    
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
            
            // Save the context.
            NSError *error = nil;
            if (![passOnContext save:&error]) {
                NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
                abort();
            }
        
        }
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
