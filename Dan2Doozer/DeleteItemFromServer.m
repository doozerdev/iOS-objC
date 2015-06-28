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
            NSLog(@"successful JSON delete");
            
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

@end
