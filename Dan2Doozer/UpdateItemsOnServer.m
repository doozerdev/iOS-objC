//
//  UpdateItemsOnServer.m
//  Doozer
//
//  Created by Daniel Apone on 6/15/15.
//  Copyright (c) 2015 Daniel Apone. All rights reserved.
//

#import "UpdateItemsOnServer.h"
#import "AFNetworking.h"
#import "Item.h"
#import "AppDelegate.h"
#import "DoozerSyncManager.h"
#import "Constants.h"

@implementation UpdateItemsOnServer


- (void)updateItemsOnServer: (NSMutableArray *)itemsToUpdate :(NSManagedObjectContext *)passOnContext :(void(^)(int))handler;{
    
    _completionHandler = [handler copy];
    
    NSInteger numItems = [itemsToUpdate count];
    
    if ((int)numItems == 0) {
        int tempNum = 0;
        _completionHandler(tempNum);
        //NSLog(@"right after setting the completion handler in the IF statement");
        _completionHandler = nil;
        
    }else{
    int loopcount = 0;
    
    for(id itemIdToUpdate in itemsToUpdate){
        //NSLog(@"ItemID to updated is ==== %@", itemIdToUpdate);
        loopcount += 1;
        //NSLog(@"loopcount = %d", loopcount);
        
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
        
        NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
        
        if (itemToUpdate.archive == NULL) {
            if (itemToUpdate.title.length > 0) {
                params[@"title"] = itemToUpdate.title;
            }else{
                params[@"title"] = @" ";
            }
            params[@"order"] = itemToUpdate.order;
            params[@"done"] = [NSNumber numberWithBool: itemToUpdate.done.boolValue];
            if (itemToUpdate.duedate) {
                params[@"duedate"] = itemToUpdate.duedate;
            }else{
                params[@"duedate"] = @"";
            }
            if (itemToUpdate.parent) {
                params[@"parent"] = itemToUpdate.parent;
            }
            if (itemToUpdate.notes){
                params[@"notes"] = itemToUpdate.notes;
            }
            if (itemToUpdate.color){
                params[@"color"] = itemToUpdate.color;
            }
        }else{
            params[@"archive"] = itemToUpdate.archive;
        }
        
        AppDelegate* appDelegate = [AppDelegate sharedAppDelegate];
        NSString *urlBase = [NSString stringWithFormat:@"%@items/%@", appDelegate.SERVER_URI, itemToUpdate.itemId];
        
        [manager PUT:urlBase parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"Successful JSON update %@", responseObject);

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
            
            
            if (loopcount == (int)numItems) {
                //NSLog(@"right before setting the completion handler");
                _completionHandler(loopcount);
                //NSLog(@"right after setting the completion handler");
                _completionHandler = nil;
            }
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Error: %@", error);
            _completionHandler(-1);
            _completionHandler = nil;
        }];
    }

    }
}

+(void)updateThisItem:(Item *)itemToUpdate{
    
    AppDelegate* appDelegate = [AppDelegate sharedAppDelegate];
    NSManagedObjectContext* context = appDelegate.managedObjectContext;
    NSLog(@"updated at value == %@", itemToUpdate.updated_at);
    
    itemToUpdate.updated_at = [NSDate date];
    
    NSString *itemIdCharacter = [itemToUpdate.itemId substringToIndex:1];
    //NSLog(@"first char = %@", itemIdCharacter);
    NSMutableArray *newArrayOfItemsToUpdate = [[[NSUserDefaults standardUserDefaults] valueForKey:@"itemsToUpdate"]mutableCopy];
    
    BOOL inQueueAlready = NO;
    
    for (NSString *eachString in newArrayOfItemsToUpdate){
        if ([itemToUpdate.itemId isEqualToString:eachString]) {
            inQueueAlready = YES;
        }
    }

    if ([itemIdCharacter isEqualToString:@"1"] || inQueueAlready) {
        //do nothing
    }else{
        [newArrayOfItemsToUpdate addObject:itemToUpdate.itemId];
        [[NSUserDefaults standardUserDefaults] setObject:newArrayOfItemsToUpdate forKey:@"itemsToUpdate"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }

    // Save the context.
    NSError *error = nil;
    if (![context save:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    [DoozerSyncManager syncWithServer];
    //NSLog(@"End of UpdateThisItem Method");

    
}





@end
