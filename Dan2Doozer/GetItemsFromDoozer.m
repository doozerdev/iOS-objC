//
//  GetItemsFromDoozer.m
//  Doozer
//
//  Created by Daniel Apone on 6/3/15.
//  Copyright (c) 2015 Daniel Apone. All rights reserved.
//

#import "GetItemsFromDoozer.h"
#import "AFNetworking.h"
#import "DoozerSyncManager.h"


@implementation GetItemsFromDoozer

- (void)getItemsOnServer:(void(^)(NSMutableArray *))handler;{
    _completionHandler = [handler copy];
    
    __block NSMutableArray * itemsArray = [[NSMutableArray alloc] init];
    
    NSDate *syncDate = [[NSUserDefaults standardUserDefaults] valueForKey:@"LastSuccessfulSync"];
    
    NSString* dateString = [NSString stringWithFormat:@"%@", syncDate];
    
    double currentTime = [[NSDate date] timeIntervalSince1970];
    NSLog(@"current time is %f, and last sync time was %@", currentTime, dateString);
    
    NSDictionary *params = nil;
    if (syncDate == NULL) {
        //do nothing
    }else{
        params = @{@"last_sync" : dateString};
        }
    
    NSString * NewURL = @"http://warm-atoll-6588.herokuapp.com/api/items";
    
    NSString *currentSessionId = [[NSUserDefaults standardUserDefaults] valueForKey:@"UserLoginIdSession"];
    
    AFHTTPRequestOperationManager *cats = [AFHTTPRequestOperationManager manager];
    
    [cats.requestSerializer setValue:currentSessionId forHTTPHeaderField:@"sessionId"];    
    
    [cats GET:NewURL parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {

        NSDictionary *jsonDict = (NSDictionary *) responseObject;
        itemsArray = [jsonDict objectForKey:@"items"];
        //NSLog(@" heres' the server response =%@", itemsArray);
        NSLog(@"Count of items from doozer server = %lu", itemsArray.count);
        
        _completionHandler(itemsArray);
        _completionHandler = nil;
        
      }
      failure:^(AFHTTPRequestOperation *operation, NSError *error) {
          NSLog(@"Error: %@", error);
 
          if ([operation.response statusCode] == 401){
              
              NSLog(@"setting sessionID to nil");
              NSString * sessionID = nil;
              [[NSUserDefaults standardUserDefaults] setObject:sessionID forKey:@"UserLoginIdSession"];
              [[NSUserDefaults standardUserDefaults] synchronize];
              
              [DoozerSyncManager syncWithServer];
              
              
          }
          
      }];
}

@end
