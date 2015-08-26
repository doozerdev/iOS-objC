//
//  AddItemViewController.h
//  Doozer
//
//  Created by Daniel Apone on 7/20/15.
//  Copyright © 2015 Daniel Apone. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "Item.h"

@protocol AddItemViewControllerDelegate;


@interface AddItemViewController : UIViewController <UIGestureRecognizerDelegate, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>

@property (nonatomic, weak) id<AddItemViewControllerDelegate> delegate;


@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;

@property BOOL showAllLists;
@property Item *selectedList;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *lowerContentPanel;

- (void)closeDownView;


@end


@protocol AddItemViewControllerDelegate <NSObject>

- (void)reloadAndDrawLists;

@end