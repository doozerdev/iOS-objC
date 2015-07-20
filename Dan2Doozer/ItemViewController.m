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
        
        
        self.showDatePicker = NO;
        NSDate *newDate = self.datePicker.date;
        checkItem.duedate = newDate;
        checkItem.notes = fieldNotes.text;
        
        if (fieldTitle.text.length == 0) {
            //do nothing
        }else{
            checkItem.title = fieldTitle.text;
            [UpdateItemsOnServer updateThisItem:checkItem];
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
    
    
    Item *displayItem = self.detailItem;
    Item *displayListParent = self.displayListOfItem;
    self.showDatePicker = NO;

    self.navigationItem.title = displayItem.title;
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

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    
    return 7;
}

-(void)handleTap:(UITapGestureRecognizer*)tapGesture {
    
    CGPoint location = [tapGesture locationInView:self.tableView];
    NSLog(@"location = %f,%f", location.x, location.y);
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:location];

    if (indexPath.row == 2) {
        if (self.showDatePicker) {
            //do nothing
        }else{
            self.showDatePicker = YES;
            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
        }
    }else{
        if (self.showDatePicker) {
            self.showDatePicker = NO;
            NSDate *newDate = self.datePicker.date;
            Item *itemOfNewDate = self.detailItem;
            itemOfNewDate.duedate = newDate;
            [UpdateItemsOnServer updateThisItem:itemOfNewDate];
            [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:2 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
        }
    }
    NSLog(@"row was clicked = %ld", indexPath.row);
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{

    if (self.showDatePicker && indexPath.row == 2) {
        return 216;
    }else{
        return 50;
    }
    
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"testCell" forIndexPath:indexPath];
    //cell = [tableView dequeueReusableCellWithIdentifier:@"word"];
    Item *displayItem = self.detailItem;
    cell.detailTextLabel.hidden = YES;
    [[cell viewWithTag:3] removeFromSuperview];
    
    UITextField *textField = [[UITextField alloc] init];
    textField.tag = 3;
    textField.translatesAutoresizingMaskIntoConstraints = NO;
    [cell.contentView addSubview:textField];
    [cell addConstraint:[NSLayoutConstraint constraintWithItem:textField attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:cell.textLabel attribute:NSLayoutAttributeTrailing multiplier:1 constant:8]];
    [cell addConstraint:[NSLayoutConstraint constraintWithItem:textField attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:cell.contentView attribute:NSLayoutAttributeTop multiplier:1 constant:8]];
    [cell addConstraint:[NSLayoutConstraint constraintWithItem:textField attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:cell.contentView attribute:NSLayoutAttributeBottom multiplier:1 constant:-8]];
    [cell addConstraint:[NSLayoutConstraint constraintWithItem:textField attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:cell.detailTextLabel attribute:NSLayoutAttributeTrailing multiplier:1 constant:0]];
    textField.textAlignment = NSTextAlignmentLeft;
    textField.font = [UIFont fontWithName:@"Avenir" size:12];
    textField.textColor = [UIColor blackColor];
    
    if ((int)indexPath.row == 0) {
        textField.font = [UIFont fontWithName:@"Avenir" size:16];
        textField.text = displayItem.title;
        cell.textLabel.text = @"Title";
        textField.tag = 301;
    }else if ((int)indexPath.row == 1){
        textField.font = [UIFont fontWithName:@"Avenir" size:16];
        textField.text = displayItem.notes;
        cell.textLabel.text = @"Notes";
        textField.tag = 302;
    }else if ((int)indexPath.row == 2){
        if (self.showDatePicker) {
            
            cell.textLabel.text = @" ";
            textField.text = @" ";
            self.datePicker =[[UIDatePicker alloc]initWithFrame:cell.frame];
            self.datePicker.datePickerMode=UIDatePickerModeDate;
            if (displayItem.duedate) {
                self.datePicker.date = displayItem.duedate;
            }else{
                self.datePicker.date = [NSDate date];
            }
            self.datePicker.tag = 777;
            [self.view addSubview:self.datePicker];
        } else {
            UIView *viewToRemove = [self.view viewWithTag:777];
            [viewToRemove removeFromSuperview];
            UIView *textFieldToRemove = [self.view viewWithTag:303];
            [textFieldToRemove removeFromSuperview];
            
            textField.font = [UIFont fontWithName:@"Avenir" size:16];
            textField.userInteractionEnabled = NO;
            NSString *mySmallerString = nil;
            if(displayItem.duedate){
                NSDateFormatter *df = [[NSDateFormatter alloc]init];
                [df setDateFormat:@"EEE MMM dd, yyyy"];
                mySmallerString = [df stringFromDate:displayItem.duedate];

            }else{
                mySmallerString = @" ";
            }
            textField.text = mySmallerString;
            NSLog(@"just set the text to = %@", textField.text);
            cell.textLabel.text = @"Due Date";
            textField.tag = 303;
            
        }
    }else if ((int)indexPath.row == 3){
        textField.text = displayItem.order.stringValue;
        textField.userInteractionEnabled = NO;
        textField.textColor = [UIColor grayColor];
        cell.textLabel.text = @"Order";
    }else if ((int)indexPath.row == 4){
        textField.text = displayItem.itemId;
        textField.userInteractionEnabled = NO;
        textField.textColor = [UIColor grayColor];
        cell.textLabel.text = @"Item ID";
    }else if ((int)indexPath.row == 5){
        textField.text = displayItem.parent;
        textField.userInteractionEnabled = NO;
        textField.textColor = [UIColor grayColor];
        cell.textLabel.text = @"Parent ID";
    }else{
        textField.text = @"Awesome Solution #1";
        cell.textLabel.text = @"Solution";
        textField.textColor = [UIColor grayColor];
    }
    //textField.delegate = self;
    return cell;
}

@end
