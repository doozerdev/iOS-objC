//
//  ListViewController.h
//  Doozer
//
//  Created by Daniel Apone on 5/3/15.
//  Copyright (c) 2015 Daniel Apone. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "Item.h"

@class DetailViewController;
@class MasterViewController;

@interface ListViewController : UITableViewController <NSFetchedResultsControllerDelegate, UITextFieldDelegate, UIGestureRecognizerDelegate>

@property (strong, nonatomic) id displayList;

@property (strong, nonatomic) DetailViewController *detailViewController;

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSIndexPath *superOriginalIndex;
@property (strong, nonatomic) NSMutableArray *children;

@property (weak, nonatomic) IBOutlet UINavigationItem *listNavBar;
@property BOOL allowDragging;
@property BOOL showCompleted;
@property CGPoint startPosition;
@property BOOL longPressActive;
@property BOOL isScrolling;
@property BOOL isRightSwiping;
@property BOOL isAutoScrolling;

@property (nonatomic) int rowOfNewItem;

@property NSTimer *scrollTimer;

<<<<<<< Updated upstream
@property Item *reorderedItem;
=======
@property NSIndexPath *lp_indexPath;
@property NSIndexPath *lp_sourceindexPath;
@property UIView *lp_snapshot;
@property CGPoint lp_location;
>>>>>>> Stashed changes


@end

