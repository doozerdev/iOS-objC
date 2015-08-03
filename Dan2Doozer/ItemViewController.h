//
//  ItemViewController.h
//  Doozer
//
//  Created by Daniel Apone on 6/16/15.
//  Copyright (c) 2015 Daniel Apone. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface ItemViewController : UITableViewController <NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) id detailItem;
@property (strong, nonatomic) id displayListOfItem;

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (weak, nonatomic) IBOutlet UITextField *TextFieldInCell;

@property BOOL showDatePicker;
@property BOOL showDateCells;
@property BOOL editingNotes;

@property UIDatePicker *datePicker;
@property NSDate *dateToSet;


@end
