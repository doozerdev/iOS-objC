//
//  GetItemsFromDoozer.m
//  Doozer
//
//  Created by Daniel Apone on 6/3/15.
//  Copyright (c) 2015 Daniel Apone. All rights reserved.
//

#import "GetItemsFromDoozer.h"
#import "AFNetworking.h"


@implementation GetItemsFromDoozer

- (void)getItemsOnServer:(void(^)(NSMutableArray *))handler;{
    _completionHandler = [handler copy];
    
    __block NSMutableArray * itemsArray = [[NSMutableArray alloc] init];
    //__block NSMutableArray * fetchedArray = [[NSMutableArray alloc] init];
    
    NSString *NewURL = @"http://warm-atoll-6588.herokuapp.com/api/items";
    
    NSString *currentSessionId = [[NSUserDefaults standardUserDefaults] valueForKey:@"UserLoginIdSession"];
    
    AFHTTPRequestOperationManager *cats = [AFHTTPRequestOperationManager manager];
    [cats.requestSerializer setValue:currentSessionId forHTTPHeaderField:@"sessionId"];
    
    [cats GET:NewURL parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSDictionary *jsonDict = (NSDictionary *) responseObject;
        //fetchedArray = [jsonDict objectForKey:@"items"];
        itemsArray = [jsonDict objectForKey:@"items"];
        
        //[itemsArray addObjectsFromArray:fetchedArray];
        
        _completionHandler(itemsArray);
        _completionHandler = nil;
        
        //long numberOfLists = [fetchedArray count];
        //int loopCount = 0;
        
        /*
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
                    //[self meshDataStores:passOnContext:itemsArray];
                    //NSLog(@"print the whole array of items = %@", itemsArray);
                    _completionHandler(itemsArray);
                    _completionHandler = nil;
                    
                }
                
                
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                NSLog(@"Error: %@", error);
            }];
         
        }
         */
    }
      failure:^(AFHTTPRequestOperation *operation, NSError *error) {
          NSLog(@"Error: %@", error);
          
      }];
}

@end
