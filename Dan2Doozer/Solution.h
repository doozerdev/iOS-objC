//
//  Solution.h
//  Doozer
//
//  Created by Daniel Apone on 9/4/15.
//  Copyright (c) 2015 Daniel Apone. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface Solution : NSManagedObject

@property (nonatomic, retain) NSString *sol_ID;
@property (nonatomic, retain) NSString *sol_title;
@property (nonatomic, retain) NSString *source;
@property (nonatomic, retain) NSString *sol_description;
@property (nonatomic, retain) NSNumber *price;
@property (nonatomic, retain) NSString *address;
@property (nonatomic, retain) NSString *phone_number;
@property (nonatomic, retain) NSString *open_hours;
@property (nonatomic, retain) NSString *link;
@property (nonatomic, retain) NSString *tags;
@property (nonatomic, retain) NSString *expire_date;
@property (nonatomic, retain) NSString *img_link;
@property (nonatomic, retain) NSString *notes;
@property (nonatomic, retain) NSNumber *archive;
@property (nonatomic, retain) NSString *state;
@property (nonatomic, retain) NSDate *date_associated;
@property (nonatomic, retain) NSString *item_id;





@end
