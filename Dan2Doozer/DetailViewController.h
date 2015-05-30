//
//  DetailViewController.h
//  Dan2Doozer
//
//  Created by Daniel Apone on 5/1/15.
//  Copyright (c) 2015 Daniel Apone. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface DetailViewController : UIViewController <NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) id detailItem;
@property (strong, nonatomic) id displayListOfItem;
@property (weak, nonatomic) IBOutlet UITextField *ItemTitleField;

@property (weak, nonatomic) IBOutlet UILabel *ItemIDTextLabel;
@property (weak, nonatomic) IBOutlet UILabel *ParentIDTextLabel;
@property (weak, nonatomic) IBOutlet UILabel *OrderValueLabel;
@property (weak, nonatomic) IBOutlet UILabel *DoneLabel;
@property (weak, nonatomic) IBOutlet UITextView *NotesTextArea;
@property (weak, nonatomic) IBOutlet UITextField *DueDateTextField;




@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@end

