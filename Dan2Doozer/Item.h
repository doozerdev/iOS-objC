//
//  Item.h
//  Dan2Doozer
//
//  Created by Daniel Apone on 5/1/15.
//  Copyright (c) 2015 Daniel Apone. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface Item : NSManagedObject


@property (nonatomic, retain) NSString *itemName;
@property (nonatomic, retain) NSNumber *order;
@property (nonatomic, retain) NSNumber *completed;
@property (nonatomic, retain) NSDate *createdDate;
@property (nonatomic, retain) NSString *itemId;
@property (nonatomic, retain) NSNumber *parentId;




@end
