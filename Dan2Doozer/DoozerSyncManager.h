//
//  DoozerSyncManager.h
//  Doozer
//
//  Created by Daniel Apone on 5/30/15.
//  Copyright (c) 2015 Daniel Apone. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/Coredata.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>
#import "Item.h"

@interface DoozerSyncManager : NSObject 


+ (void)syncWithServer;
+ (void)copyFromServer :(NSMutableArray *)inputArray;
+ (void)getSolutions:(Item *)item;


@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;






@end
