//
//  DeleteItemFromServer.h
//  Doozer
//
//  Created by Daniel Apone on 6/15/15.
//  Copyright (c) 2015 Daniel Apone. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/Coredata.h>
#import "Item.h"


@interface DeleteItemFromServer : NSObject

{
    void (^_completionHandler)(int doneVar);
}

- (void)deleteItemFromServer: (NSMutableArray *)itemsToDelete :(void(^)(int))handler;

+ (void)deleteThisList:(Item *)listToDelete;
+ (void)deleteThisItem:(Item *)itemToDelete;



@end
