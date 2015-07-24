//
//  CoreDataItemManager.h
//  Doozer
//
//  Created by Daniel Apone on 5/29/15.
//  Copyright (c) 2015 Daniel Apone. All rights reserved.
//

#import "Item.h"

@interface CoreDataItemManager : Item

+(int)findNumberOfUncompletedChildren :(NSString *)parent;

+(void)rebalanceItemOrderValues :(NSArray *)arrayOfItems;

+(NSInteger)findNumberOfDueItems;


    
@end
