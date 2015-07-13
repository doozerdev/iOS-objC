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

@interface ItemViewController ()

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
    UITextField *fieldDueDate = (UITextField *)[self.view viewWithTag:303];
    
    NSDateFormatter* df = [[NSDateFormatter alloc]init];
    [df setDateFormat:@"yyyy-MM-dd"];
    
    NSString *tempDueDateString = fieldDueDate.text;
    NSDate *tempDueDateNSDate = [df dateFromString:tempDueDateString];
    
    if (![checkItem.title isEqualToString:fieldTitle.text] || ![checkItem.notes isEqualToString:fieldNotes.text] || !(checkItem.duedate == tempDueDateNSDate)) {
        
        checkItem.notes = fieldNotes.text;
        checkItem.duedate = tempDueDateNSDate;
        
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
    self.navigationItem.title = displayItem.title;
    
    Item *displayListParent = self.displayListOfItem;
    
    self.view.backgroundColor = [ColorHelper getUIColorFromString:displayListParent.color :1];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    textField.font = [UIFont systemFontOfSize:12];
    textField.textColor = [UIColor blackColor];
    
    if ((int)indexPath.row == 0) {
        textField.font = [UIFont systemFontOfSize:16];
        textField.text = displayItem.title;
        cell.textLabel.text = @"Title";
        textField.tag = 301;
    }else if ((int)indexPath.row == 1){
        textField.font = [UIFont systemFontOfSize:16];
        textField.text = displayItem.notes;
        cell.textLabel.text = @"Notes";
        textField.tag = 302;
    }else if ((int)indexPath.row == 2){
        textField.font = [UIFont systemFontOfSize:16];
        NSString *mySmallerString = nil;
        if(displayItem.duedate){
            NSString *fullDateString = [NSString stringWithFormat:@"%@", displayItem.duedate];
            mySmallerString = [fullDateString substringToIndex:10];
        }else{
            NSDate *currDate = [NSDate date];
            NSString *fullDateString = [NSString stringWithFormat:@"%@", currDate];
            mySmallerString = [fullDateString substringToIndex:10];
        }
        textField.text = mySmallerString;
        cell.textLabel.text = @"Due Date";
        textField.tag = 303;
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
