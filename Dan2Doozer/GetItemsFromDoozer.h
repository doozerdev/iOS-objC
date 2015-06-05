//
//  GetItemsFromDoozer.h
//  Doozer
//
//  Created by Daniel Apone on 6/3/15.
//  Copyright (c) 2015 Daniel Apone. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GetItemsFromDoozer : NSObject
{
    void (^_completionHandler)(NSMutableArray * someArray);
}

- (void)getItemsOnServer:(void(^)(NSMutableArray *))handler;
@end
