//
//  MasterViewController.h
//  Dan2Doozer
//
//  Created by Daniel Apone on 5/1/15.
//  Copyright (c) 2015 Daniel Apone. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import <QuartzCore/QuartzCore.h>
#import "Item.h"
#import "AddItemViewController.h"


@class DetailViewController;
@class ListViewController;

@interface MasterViewController : UITableViewController <NSFetchedResultsControllerDelegate, UITextFieldDelegate, UIGestureRecognizerDelegate, AddItemViewControllerDelegate>

//@property (strong, nonatomic) DetailViewController *detailViewController;
@property (strong, nonatomic) ListViewController *listViewController;
@property (strong, nonatomic) NSMutableArray *parentArray;
@property (nonatomic) int numberOfUncompletedChildren;
@property (strong, nonatomic) NSIndexPath *originalIndex;


@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@property (nonatomic) int rowOfExpandedCell;
@property (strong, nonatomic) Item *itemToDelete;
@property BOOL addingAnItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *dueButton;

@property NSMutableArray *numberOfItemsOnLists;


@end

