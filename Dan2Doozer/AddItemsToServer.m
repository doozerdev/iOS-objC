//
//  AddItemsToServer.m
//  Doozer
//
//  Created by Daniel Apone on 6/15/15.
//  Copyright (c) 2015 Daniel Apone. All rights reserved.
//

#import "AddItemsToServer.h"
#import "AFNetworking.h"
#import "Item.h"
#import "AppDelegate.h"
#import "DoozerSyncManager.h"
#import "Constants.h"


@implementation AddItemsToServer


- (void)addItemsToServer: (NSMutableArray *)itemsToAdd :(NSManagedObjectContext *)passOnContext :(void(^)(int))handler;
{
    _completionHandler = [handler copy];
    
    NSInteger numItems = [itemsToAdd count];
    //NSLog(@"number of items to add is %ld", (long)numItems);
    
    if ((int)numItems == 0) {
        int tempNum = 0;
        _completionHandler(tempNum);
        //NSLog(@"right after setting the completion handler in the IF statement");
        _completionHandler = nil;
        
    }else{
    int loopcount = 0;
    
    for (id itemIdToAdd in itemsToAdd){
        
        loopcount += 1;
        
        
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"ItemRecord" inManagedObjectContext:passOnContext];
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        [fetchRequest setEntity:entity];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"itemId == %@", itemIdToAdd];
        [fetchRequest setPredicate:predicate];
    
        NSError *firsterror = nil;
        NSArray *results = [passOnContext executeFetchRequest:fetchRequest error:&firsterror];
        Item *itemToAdd = [results objectAtIndex:0];
        //NSLog(@"loopcount = %d and itemIDToAdd is = %@ and parentID is = %@", loopcount, itemIdToAdd, itemToAdd.parent);
    
        NSString *currentSessionId = [[NSUserDefaults standardUserDefaults] valueForKey:@"UserLoginIdSession"];
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        [manager.requestSerializer setValue:currentSessionId forHTTPHeaderField:@"sessionId"];
        NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
        params[@"order"] = itemToAdd.order;

        if (itemToAdd.title.length > 0) {
            params[@"title"] = itemToAdd.title;
            NSLog(@"adding a title with characters");
        }else{
            params[@"title"] = @" ";
            NSLog(@"adding nill title.....");
        }
        if (itemToAdd.parent == nil) {
            params[@"parent"] = @"";
        }else{
            params[@"parent"] = itemToAdd.parent;
        }
        if (itemToAdd.type) {
            params[@"type"] = itemToAdd.type;
        }
        if (itemToAdd.color){
            params[@"color"] = itemToAdd.color;
        }
        
        NSString *URLstring = [NSString stringWithFormat:@"%@items", kBaseAPIURL];
        
        [manager POST:URLstring parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"Successful JSON ADD ITEM");
        
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
                
                
                //Perhaps I should add a 'localID' field and keep the 'ServerID' as a separate field?
                //this could allow me to update the server ID field in the background with less disruption.
                //I would have to add lots of OR statements (i.e. serverID or localID to find a valid item).
                
                
                for (id eachChild in results2){
                    Item *childToModifyParent = eachChild;
                    childToModifyParent.parent = newItemId;
                    NSLog(@"modifying (%@, %@)'s parent to be %@", childToModifyParent.title, childToModifyParent.itemId, newItemId);
                }
            
            }
        
            // Save the context.
            NSError *error = nil;
            if (![passOnContext save:&error]) {
                NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
                abort();
            }
            
            
            if (itemToAdd.parent == nil){
                NSMutableArray *newListsToAdd = [[[NSUserDefaults standardUserDefaults] valueForKey:@"listsToAdd"]mutableCopy];
                NSMutableArray *newListsToAddCopy =[[NSMutableArray alloc]init];
                for (NSString * arrayElement in newListsToAdd) {
                    if ([arrayElement isEqualToString:itemIdToAdd]){
                        
                    }else{
                        [newListsToAddCopy addObject:arrayElement];
                    }
                }
                [[NSUserDefaults standardUserDefaults] setObject:newListsToAddCopy forKey:@"listsToAdd"];
            }else{
                NSMutableArray *newItemsToAdd = [[[NSUserDefaults standardUserDefaults] valueForKey:@"itemsToAdd"]mutableCopy];
                NSMutableArray *newItemsToAddCopy =[[NSMutableArray alloc]init];
                for (NSString * arrayElement in newItemsToAdd) {
                    if ([arrayElement isEqualToString:itemIdToAdd]){
                    
                    }else{
                        [newItemsToAddCopy addObject:arrayElement];
                    }
                }
                [[NSUserDefaults standardUserDefaults] setObject:newItemsToAddCopy forKey:@"itemsToAdd"];
            }
            
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

+(void)addThisItem:(Item *)itemToAdd{
        
    AppDelegate* appDelegate = [AppDelegate sharedAppDelegate];
    NSManagedObjectContext* context = appDelegate.managedObjectContext;
    
    if (itemToAdd.parent == nil) {
        NSMutableArray *newArrayOfListsToAdd = [[[NSUserDefaults standardUserDefaults] valueForKey:@"listsToAdd"]mutableCopy];
        [newArrayOfListsToAdd addObject:itemToAdd.itemId];
        [[NSUserDefaults standardUserDefaults] setObject:newArrayOfListsToAdd forKey:@"listsToAdd"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }else{
        NSMutableArray *newArrayOfItemsToAdd = [[[NSUserDefaults standardUserDefaults] valueForKey:@"itemsToAdd"]mutableCopy];
        [newArrayOfItemsToAdd addObject:itemToAdd.itemId];
        [[NSUserDefaults standardUserDefaults] setObject:newArrayOfItemsToAdd forKey:@"itemsToAdd"];
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
