//
//  UpdateItemsOnServer.h
//  Doozer
//
//  Created by Daniel Apone on 6/15/15.
//  Copyright (c) 2015 Daniel Apone. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/Coredata.h>

@interface UpdateItemsOnServer : NSObject

{
    void (^_completionHandler)(int doneVar);
}

- (void)updateItemsOnServer: (NSMutableArray *)itemsToUpdate :(NSManagedObjectContext *)passOnContext :(void(^)(int))handler;


@end
