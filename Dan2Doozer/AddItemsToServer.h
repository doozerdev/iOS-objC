//
//  AddItemsToServer.h
//  Doozer
//
//  Created by Daniel Apone on 6/15/15.
//  Copyright (c) 2015 Daniel Apone. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/Coredata.h>
#import "Item.h"


@interface AddItemsToServer : NSObject

{
    void (^_completionHandler)(int doneVar);
}

- (void)addItemsToServer: (NSMutableArray *)itemsToAdd :(NSManagedObjectContext *)passOnContext :(void(^)(int))handler;

+(void)addThisItem:(Item *)itemToAdd;




@end

