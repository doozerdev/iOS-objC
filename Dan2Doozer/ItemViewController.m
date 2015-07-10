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
    
    //NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    //UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"testCell" forIndexPath:indexPath];
    
    //NSLog(@" cell text = %@", cell.textLabel.text);
    
    UITextField *fieldTitle = (UITextField *)[self.view viewWithTag:301];
    UITextField *fieldNotes = (UITextField *)[self.view viewWithTag:302];
    UITextField *fieldDueDate = (UITextField *)[self.view viewWithTag:303];
    /*
    NSLog(@" Text Field text = %@", fieldTitle.text);
    NSLog(@" Text Field text = %@", fieldNotes.text);
    NSLog(@" Text Field text = %@", fieldDueDate.text);
    */
    
    NSDateFormatter* df = [[NSDateFormatter alloc]init];
    [df setDateFormat:@"yyyy-MM-dd"];
    
    NSString *tempDueDateString = fieldDueDate.text;
    NSDate *tempDueDateNSDate = [df dateFromString:tempDueDateString];
    
    if (![checkItem.title isEqualToString:fieldTitle.text] || ![checkItem.notes isEqualToString:fieldNotes.text] || !(checkItem.duedate == tempDueDateNSDate)) {
        NSManagedObjectContext *context = self.managedObjectContext;
        
        checkItem.title = fieldTitle.text;
        checkItem.notes = fieldNotes.text;
        checkItem.duedate = tempDueDateNSDate;
         
        NSString *itemIdCharacter = [checkItem.itemId substringToIndex:1];
        //NSLog(@"first char = %@", itemIdCharacter);
        
        if ([itemIdCharacter isEqualToString:@"1"]) {
            //do nothing
        }else{
            NSMutableArray *newArrayOfItemsToUpdate = [[[NSUserDefaults standardUserDefaults] valueForKey:@"itemsToUpdate"]mutableCopy];
            [newArrayOfItemsToUpdate addObject:checkItem.itemId];
            [[NSUserDefaults standardUserDefaults] setObject:newArrayOfItemsToUpdate forKey:@"itemsToUpdate"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
        
        // Save the context.
        NSError *error = nil;
        if (![context save:&error]) {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
        [DoozerSyncManager syncWithServer];
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

    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
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


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
 */

//#pragma mark - Fetched results controller

/*
- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"ItemRecord" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];
    
    Item *currentItem = self.detailItem;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"itemId == %@", currentItem.itemId];
    [fetchRequest setPredicate:predicate];
    
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"order" ascending:YES];
    NSArray *sortDescriptors = @[sortDescriptor];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:@"Detail"];
    aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;
    [NSFetchedResultsController deleteCacheWithName:@"Detail"];
    
    
    NSError *error = nil;
    if (![self.fetchedResultsController performFetch:&error]) {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _fetchedResultsController;
}

*/
@end
