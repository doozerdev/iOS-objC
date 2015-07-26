//
//  DueItemsViewController.h
//  Doozer
//
//  Created by Daniel Apone on 7/23/15.
//  Copyright © 2015 Daniel Apone. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>


@interface DueItemsViewController : UITableViewController


@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;

@property NSInteger numberOfLists;
@property NSMutableArray *sectionsToShow;

@property BOOL isRightSwiping;
@property BOOL isScrolling;



@end
