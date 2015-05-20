//
//  Item.h
//  Dan2Doozer
//
//  Created by Daniel Apone on 5/1/15.
//  Copyright (c) 2015 Daniel Apone. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface Item : NSManagedObject


@property (nonatomic, retain) NSString *title;
@property (nonatomic) BOOL done;
@property (nonatomic) BOOL archive;
@property (nonatomic, retain) NSString *parent;
@property (nonatomic, retain) NSNumber *order;
@property (nonatomic, retain) NSDate *duedate;
@property (nonatomic, retain) NSString *user_id;
@property (nonatomic, retain) NSString *notes;
@property (nonatomic, retain) NSString *solutions;
@property (nonatomic, retain) NSDate *updated_at;

@property (nonatomic, retain) NSString *itemId;





@end
