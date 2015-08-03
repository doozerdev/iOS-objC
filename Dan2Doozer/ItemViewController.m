//
//  ItemViewController.m
//  Doozer
//
//  Created by Daniel Apone on 6/16/15.
//  Copyright (c) 2015 Daniel Apone. All rights reserved.
//

#import "ItemViewController.h"
#import "ListViewController.h"
#import "Item.h"
#import "AFNetworking.h"
#import "DoozerSyncManager.h"
#import "ColorHelper.h"
#import "UpdateItemsOnServer.h"
#import "Intercom.h"
#import "ItemCustomCell.h"
#import "AppDelegate.h"

@interface ItemViewController () <UIGestureRecognizerDelegate>

@end

@implementation ItemViewController

- (void)setDetailItem:(id)newDetailItem {
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
        
    }
}

-(void) viewWillDisappear:(BOOL)animated {
    Item *checkItem = self.detailItem;
    
    UITextField *fieldTitle = (UITextField *)[self.view viewWithTag:301];
    UITextField *fieldNotes = (UITextField *)[self.view viewWithTag:302];
 
    if (![checkItem.title isEqualToString:fieldTitle.text] || ![checkItem.notes isEqualToString:fieldNotes.text] || self.showDatePicker) {
        
        if (self.showDatePicker) {
            self.showDatePicker = NO;
            NSDate *newDate = self.datePicker.date;
            checkItem.duedate = newDate;
        }

        checkItem.notes = fieldNotes.text;
        
        if (fieldTitle.text.length == 0) {
            //do nothing
        }else{
            checkItem.title = fieldTitle.text;
            [UpdateItemsOnServer updateThisItem:checkItem];
            int timestamp = [[NSDate date] timeIntervalSince1970];
            NSString *date = [NSString stringWithFormat:@"%d", timestamp];
            [Intercom logEventWithName:@"Edited_Item_Properties" metaData: @{@"date": date}];
        }
    }

    [super viewWillDisappear:animated];
}

- (void)setDisplayListOfItem:(id)newDisplayListOfItem {
    if (_displayListOfItem != newDisplayListOfItem) {
        _displayListOfItem = newDisplayListOfItem;
        
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    //Item *displayItem = self.detailItem;
    Item *displayListParent = self.displayListOfItem;
    self.showDatePicker = NO;
    self.editingNotes = NO;

    self.navigationItem.title = @"";
    UIColor *tempColor = [ColorHelper getUIColorFromString:displayListParent.color :1];
    self.view.backgroundColor = tempColor;
    self.navigationController.navigationBar.barStyle  = UIBarStyleBlack;
    self.navigationController.navigationBar.barTintColor = tempColor;

    [self.navigationController.navigationBar setTitleTextAttributes: @{
                                                                       NSForegroundColorAttributeName: [UIColor whiteColor],
                                                                       NSFontAttributeName: [UIFont fontWithName:@"Avenir" size:20],
                                                                       }];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [self.view addGestureRecognizer:tapGesture];
    tapGesture.delegate = self;
    
    

    

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    
    return YES;
}
- (IBAction)pressedDoneButton:(UIButton*)button {
    
    switch (button.tag) {
        case 1:
            [self endNotesEditing];
            break;
            
        case 7:
            [self endDateEditing];
            break;
        default:
            break;
    }
    
}

- (void)endNotesEditing{
    
    [self.view endEditing:YES];
    ItemCustomCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    Item *displayedItem = [self.fetchedResultsController.fetchedObjects objectAtIndex:0];
    displayedItem.notes = cell.CellTextView.text;
    
    [UpdateItemsOnServer updateThisItem:displayedItem];
    
    self.editingNotes = NO;
    
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];

    
}


-(void)endDateEditing{
    
    //ItemCustomCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:7 inSection:0]];
    Item *displayedItem = [self.fetchedResultsController.fetchedObjects objectAtIndex:0];
    displayedItem.duedate = self.datePicker.date;
    
    [UpdateItemsOnServer updateThisItem:displayedItem];

    self.showDatePicker = NO;

    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:7 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];

}

-(void)setTextFieldToBeResponder {
    
    ItemCustomCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    [cell.CellTextView becomeFirstResponder];
    
    
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    
    return 8;
}

-(void)handleTap:(UITapGestureRecognizer*)tapGesture {
    
    CGPoint location = [tapGesture locationInView:self.tableView];
    //NSLog(@"location = %f,%f", location.x, location.y);
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:location];
    
    ItemCustomCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    
    
    if (self.editingNotes) {
        if (indexPath.row != 1) {
            [self endNotesEditing];
        }
    }else{
        switch (indexPath.row) {
            case 0:
                [cell.CellTextView becomeFirstResponder];
                break;
            case 1:
                
                if (!self.editingNotes) {
                    self.editingNotes = YES;
                    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];

                }
                break;
            case 2:
                
                if (self.showDateCells) {
                    self.showDateCells = NO;
                }else{
                    self.showDateCells = YES;
                }
                [self.tableView reloadRowsAtIndexPaths:@[
                                                         indexPath,
                                                         [NSIndexPath indexPathForRow:3 inSection:0],
                                                         [NSIndexPath indexPathForRow:4 inSection:0],
                                                         [NSIndexPath indexPathForRow:5 inSection:0],
                                                         [NSIndexPath indexPathForRow:6 inSection:0]
                                                         
                                                         ]
                                      withRowAnimation:UITableViewRowAnimationNone];
                break;
            case 6:
                if (self.showDatePicker) {
                    //do nothing
                }else{
                    self.showDateCells = NO;
                    self.showDatePicker = YES;
                    self.dateToSet = [NSDate date];
                    
                    [self.tableView reloadRowsAtIndexPaths:@[
                                                             [NSIndexPath indexPathForRow:2 inSection:0],
                                                             [NSIndexPath indexPathForRow:3 inSection:0],
                                                             [NSIndexPath indexPathForRow:4 inSection:0],
                                                             [NSIndexPath indexPathForRow:5 inSection:0],
                                                             [NSIndexPath indexPathForRow:6 inSection:0],
                                                             [NSIndexPath indexPathForRow:7 inSection:0]
                                                             ]
                                          withRowAnimation:UITableViewRowAnimationNone];
                }
                break;
                
            case 7:
                //NSLog(@"clicked on row 7");
                
                break;
            default:
                break;
        }
    }
    


}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    //NSLog(@"height for row is callled now - row %ld", (long)indexPath.row);
    
    switch (indexPath.row) {
        case 0:
            return 70;
            break;
        case 1:
            if (self.editingNotes) {
                return 200;
            } else {
                return 100;
            }
            break;
        case 2:
            return 60;
            break;
        case 3:
            if (self.showDateCells) {
                return 60;
            }else{
                return 0;
            }
            break;
        case 4:
            if (self.showDateCells) {
                return 60;
            }else{
                return 0;
            }
            break;
        case 5:
            if (self.showDateCells) {
                return 60;
            }else{
                return 0;
            }
            break;
        case 6:
            if (self.showDateCells) {
                return 60;
            }else{
                return 0;
            }
            break;
        case 7:
            if (self.showDatePicker) {
                return 250;
            }else{
                return 0;
            }
            break;
       /*
        case 8:
            return 60;
            break;
            
        */
        default:
            return 60;
            break;
    }
    
}



- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Item *displayItem = [self.fetchedResultsController.fetchedObjects objectAtIndex:0];
    
    //NSLog(@"display item = %@", displayItem);
    Item *parentList = self.displayListOfItem;
    ItemCustomCell *cell = [tableView dequeueReusableCellWithIdentifier:@"titleCell" forIndexPath:indexPath];

    //NSLog(@"cell for row at index path is called now - row %ld", (long)indexPath.row);
    UIColor *background = [ColorHelper getUIColorFromString:parentList.color :1];
    cell.backgroundColor = background;
    cell.CellTextView.backgroundColor = background;
    cell.CellTextView.font = [UIFont fontWithName:@"Avenir-Medium" size:17];
    cell.CellTextView.textColor = [UIColor whiteColor];


    
    if (indexPath.row == 0) {
        cell.CellTextView.text = displayItem.title;
        cell.DoneButton.hidden = YES;
        cell.CellTextLabel.hidden = YES;
        cell.CellTextView.tintColor = [UIColor whiteColor];

        
        [cell addConstraint:[NSLayoutConstraint constraintWithItem:cell.CellTextView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:cell attribute:NSLayoutAttributeBottom multiplier:1 constant:-4]];

    }else if (indexPath.row == 1){
        cell.CellTextView.hidden = NO;
        cell.CellTextView.tintColor = [UIColor whiteColor];
        cell.CellTextLabel.hidden = YES;

        NSLog(@"notes for this item = %@, and length is %lu", displayItem.notes, (unsigned long)displayItem.notes.length);
        
        if (displayItem.notes.length > 1) {
            cell.CellTextView.text = displayItem.notes;


        }else{
            cell.CellTextView.text = @"Add some notes here...";
            cell.CellTextView.font = [UIFont fontWithName:@"Avenir-MediumOblique" size:17];
            cell.CellTextView.textColor = [UIColor colorWithRed:255 green:255 blue:255 alpha:0.5];

        }

        
        if (self.editingNotes) {
            cell.DoneButton.hidden = NO;
            cell.DoneButton.tag = 1;
            cell.CellTextView.textColor = [UIColor whiteColor];
            cell.CellTextView.font = [UIFont fontWithName:@"Avenir-Medium" size:17];
            
            if (displayItem.notes.length > 0) {
                cell.CellTextView.text = displayItem.notes;
            }else{
                cell.CellTextView.text = @"";
            }
            
        
            [cell addConstraint:[NSLayoutConstraint constraintWithItem:cell.CellTextView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:cell attribute:NSLayoutAttributeBottom multiplier:1 constant:-30]];
                        
            [self performSelector:@selector(setTextFieldToBeResponder) withObject:nil afterDelay:0.1f];
            


            
        }else{
            cell.DoneButton.hidden = YES;
            
            [cell addConstraint:[NSLayoutConstraint constraintWithItem:cell.CellTextView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:cell attribute:NSLayoutAttributeBottom multiplier:1 constant:-4]];


        }

    }
    
    
    else if (indexPath.row == 2){
        
        cell.DoneButton.hidden = YES;
        cell.CellTextView.hidden = YES;
        cell.CellTextLabel.hidden = NO;
        
        NSString *titleText = @"blank";
        if (self.showDateCells) {
            titleText = [NSString stringWithFormat:@"Due Someday"];
        }else if (self.showDatePicker){
            
                NSDateFormatter *df = [[NSDateFormatter alloc]init];
                [df setDateFormat:@"EEE MMM dd, yyyy"];
                NSString * dateString = [df stringFromDate:self.dateToSet];
            
            titleText = [NSString stringWithFormat:@"Due %@", dateString];
        }
        else {
            titleText = [NSString stringWithFormat:@"Due Someday \U000025BC\U0000FE0E"];
        }
        
        cell.CellTextLabel.text = titleText;

        

        
    }else if (indexPath.row == 3){
        
        cell.CellTextLabel.text = @"        Today";
        cell.CellTextView.hidden = YES;
        cell.DoneButton.hidden = YES;
        
        
    }else if (indexPath.row == 4){
        
        cell.CellTextLabel.text = @"        Tomorrow";
        cell.CellTextView.hidden = YES;
        cell.DoneButton.hidden = YES;


    }else if (indexPath.row == 5){
        
        cell.CellTextLabel.text = @"        Someday";
        cell.CellTextView.hidden = YES;
        cell.DoneButton.hidden = YES;
        
    }else if (indexPath.row == 6){
        
        cell.CellTextLabel.text = @"        Pick a Date";
        cell.CellTextView.hidden = YES;
        cell.DoneButton.hidden = YES;
        
    }else if (indexPath.row == 7){
        cell.CellTextLabel.hidden = YES;
        cell.CellTextView.hidden = YES;

        if (self.showDatePicker) {

            
            cell.CellTextView.hidden = YES;
            self.datePicker =[[UIDatePicker alloc]initWithFrame:cell.frame];
            self.datePicker.datePickerMode=UIDatePickerModeDate;
            
            [self.datePicker setValue:[UIColor whiteColor] forKey:@"textColor"];

            if (displayItem.duedate) {
                self.datePicker.date = displayItem.duedate;
            }else{
                self.datePicker.date = [NSDate date];
            }
            
            [self.datePicker addTarget:self
                       action:@selector(datePickerValueChanged:)
             forControlEvents:UIControlEventValueChanged];
            
            cell.DoneButton.hidden = NO;
            cell.DoneButton.tag = 7;
            self.datePicker.tag = 777;
            self.datePicker.alpha = 0;
            [self.view addSubview:self.datePicker];
            
            [UIView animateWithDuration:0.5 animations:^{
                
                self.datePicker.alpha = 1;
                
            } completion:^(BOOL finished) {

            }];

        } else {
            UIView *viewToRemove = [self.view viewWithTag:777];
            [viewToRemove removeFromSuperview];
            cell.DoneButton.hidden = YES;

        }
    }

    return cell;
    
}


- (void)datePickerValueChanged:(id)sender{
    UIDatePicker *picker = (UIDatePicker *)sender;
    
    NSLog(@"showDatePicker = %d, showDateCells = %d", (int)self.showDatePicker, (int)self.showDateCells);
    
    self.dateToSet = [picker date];
    
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:2 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark - Fetched results controller


- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    
    AppDelegate* appDelegate = [AppDelegate sharedAppDelegate];
    NSManagedObjectContext* context = appDelegate.managedObjectContext;
    
    Item *item = self.detailItem;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"ItemRecord" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"itemId == %@", item.itemId];
    [fetchRequest setPredicate:predicate];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"order" ascending:YES];
    NSArray *sortDescriptors = @[sortDescriptor];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:context sectionNameKeyPath:nil cacheName:@"Master"];
    self.fetchedResultsController = aFetchedResultsController;
    [NSFetchedResultsController deleteCacheWithName:@"Master"];
    
    
    NSError *error = nil;
    if (![self.fetchedResultsController performFetch:&error]) {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _fetchedResultsController;
}


@end
