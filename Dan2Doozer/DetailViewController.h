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
@property (weak, nonatomic) IBOutlet UITextField *ItemTitleField;
@property (weak, nonatomic) IBOutlet UITextField *OrderValueField;
@property (weak, nonatomic) IBOutlet UITextField *CompletedField;
@property (weak, nonatomic) IBOutlet UITextField *CreationDateField;

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@end

