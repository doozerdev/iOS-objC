//
//  DeleteItemFromServer.m
//  Doozer
//
//  Created by Daniel Apone on 6/15/15.
//  Copyright (c) 2015 Daniel Apone. All rights reserved.
//

#import "DeleteItemFromServer.h"
#import "AFNetworking.h"
#import "Item.h"
#import "AppDelegate.h"
#import "DoozerSyncManager.h"

@implementation DeleteItemFromServer

- (void)deleteItemFromServer: (NSMutableArray *)itemsToDelete :(void(^)(int))handler;
{
    _completionHandler = [handler copy];
    
    NSInteger numItems = [itemsToDelete count];
    //NSLog(@"number of items to add is %ld", (long)numItems);
    
    if ((int)numItems == 0) {
        int tempNum = 0;
        _completionHandler(tempNum);
        //NSLog(@"right after setting the completion handler in the IF statement");
        _completionHandler = nil;
        
    }else{
    
    int loopcount = 0;
    
    for (id itemIdToDelete in itemsToDelete){
        
        loopcount += 1;
        //NSLog(@"loopcount = %d", loopcount);
        
        NSString *currentSessionId = [[NSUserDefaults standardUserDefaults] valueForKey:@"UserLoginIdSession"];
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        [manager.requestSerializer setValue:currentSessionId forHTTPHeaderField:@"sessionId"];
        
        NSString *URL = [NSString stringWithFormat:@"https://warm-atoll-6588.herokuapp.com/api/items/%@/archive", itemIdToDelete];
        
        [manager DELETE:URL parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"successful JSON delete %@", responseObject);
            
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
            
            
            if (loopcount == (int)numItems) {
                //NSLog(@"right before setting the completion handler");
                _completionHandler(loopcount);
                //NSLog(@"right after setting the completion handler");
                _completionHandler = nil;
            }
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Error: %@", error);
        }];
    }

    }
}

+ (void)deleteThisList:(Item *)listToDelete{
    
    AppDelegate* appDelegate = [AppDelegate sharedAppDelegate];
    NSManagedObjectContext* context = appDelegate.managedObjectContext;
    
    [context deleteObject:listToDelete];
    
    NSMutableArray *listsToAdd = [[[NSUserDefaults standardUserDefaults] valueForKey:@"listsToAdd"]mutableCopy];
    NSMutableArray *newListsToAdd = [[NSMutableArray alloc]init];
    int matchCount = 0;
    for(id eachElement in listsToAdd){
        if ([listToDelete.itemId isEqualToString:eachElement]){
            matchCount +=1;
        }else{
            [newListsToAdd addObject:eachElement];
        }
    }
    [[NSUserDefaults standardUserDefaults] setObject:newListsToAdd forKey:@"listsToAdd"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    if (matchCount == 0){
        NSMutableArray *itemsToDelete = [[[NSUserDefaults standardUserDefaults] valueForKey:@"itemsToDelete"]mutableCopy];
        [itemsToDelete addObject:listToDelete.itemId];
        [[NSUserDefaults standardUserDefaults] setObject:itemsToDelete forKey:@"itemsToDelete"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        NSLog(@"items to delete = %@", itemsToDelete);
    }
    
    // Save the context.
    NSError *error = nil;
    if (![context save:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    [DoozerSyncManager syncWithServer];
}

+ (void)deleteThisItem:(Item *)itemToDelete{
    
    AppDelegate* appDelegate = [AppDelegate sharedAppDelegate];
    NSManagedObjectContext* context = appDelegate.managedObjectContext;
    
    [context deleteObject:itemToDelete];
    
    NSMutableArray *itemsToAdd = [[[NSUserDefaults standardUserDefaults] valueForKey:@"itemsToAdd"]mutableCopy];
    NSMutableArray *newItemsToAdd = [[NSMutableArray alloc]init];
    int matchCount = 0;
    for(id eachElement in itemsToAdd){
        if ([itemToDelete.itemId isEqualToString:eachElement]){
            matchCount +=1;
        }else{
            [newItemsToAdd addObject:eachElement];
        }
    }
    [[NSUserDefaults standardUserDefaults] setObject:newItemsToAdd forKey:@"itemsToAdd"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    if (matchCount == 0){
        NSMutableArray *itemsToDelete = [[[NSUserDefaults standardUserDefaults] valueForKey:@"itemsToDelete"]mutableCopy];
        [itemsToDelete addObject:itemToDelete.itemId];
        [[NSUserDefaults standardUserDefaults] setObject:itemsToDelete forKey:@"itemsToDelete"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    // Save the context.
    NSError *error = nil;
    if (![context save:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    [DoozerSyncManager syncWithServer];

}


@end
