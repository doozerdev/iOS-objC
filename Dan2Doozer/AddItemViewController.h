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



@interface AddItemViewController : UIViewController <UIGestureRecognizerDelegate, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;

@property BOOL showAllLists;
@property Item *selectedList;

@end
