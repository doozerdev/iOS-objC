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

@implementation UpdateItemsOnServer


- (void)updateItemsOnServer: (NSMutableArray *)itemsToUpdate :(NSManagedObjectContext *)passOnContext :(void(^)(int))handler;{
    
    _completionHandler = [handler copy];
    
    NSInteger numItems = [itemsToUpdate count];
    //NSLog(@"number of items to update is %ld", (long)numItems);
    
    
    if ((int)numItems == 0) {
        int tempNum = 0;
        _completionHandler(tempNum);
        NSLog(@"right after setting the completion handler in the IF statement");
        _completionHandler = nil;
        
    }else{
    int loopcount = 0;
    
    for(id itemIdToUpdate in itemsToUpdate){
        
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
        }];
    }

    }
    
}





@end
