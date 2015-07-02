//
//  MasterViewController.m
//  Dan2Doozer
//
//  Created by Daniel Apone on 5/1/15.
//  Copyright (c) 2015 Daniel Apone. All rights reserved.
//

#include <stdlib.h>

#import "MasterViewController.h"
#import "ListViewController.h"
#import "LoginViewController.h"
#import "Item.h"
#import "AFNetworking.h"
#import "CoreDataItemManager.h"
#import "DoozerSettingsManager.h"
#import "DoozerSyncManager.h"

@interface MasterViewController () <UITextFieldDelegate>


@end

@implementation MasterViewController

- (UIColor *)returnUIColor:(int)numPicker :(float)alpha {
    UIColor *returnValue = nil;
    
    if (numPicker == 0) {
        returnValue = [UIColor colorWithRed:46/255. green:179/255. blue:193/255. alpha:alpha]; //blue
    }
    else if (numPicker == 1){
        returnValue = [UIColor colorWithRed:134/255. green:194/255. blue:63/255. alpha:alpha]; //green
    }
    else if (numPicker == 2){
        returnValue = [UIColor colorWithRed:255/255. green:107/255. blue:107/255. alpha:alpha]; //red
    }
    else if (numPicker == 3){
        returnValue = [UIColor colorWithRed:198/255. green:99/255. blue:175/255. alpha:alpha]; //purple
    }
    else if (numPicker == 4){
        returnValue = [UIColor colorWithRed:236/255. green:183/255. blue:0/255. alpha:alpha]; //yellow
    }
    else{
        returnValue = [UIColor whiteColor];
    }
    return returnValue;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    NSLog(@"text field is beginning editting");
    [textField performSelector:@selector(selectAll:) withObject:nil afterDelay:0.0];

    return YES;
}

// It is important for you to hide the keyboard
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    NSString *currentText = textField.text;
    
    Item *itemInCell = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:self.rowOfExpandedCell inSection:0]];
    
    NSLog(@"old item title is %@", itemInCell.title);
    
    itemInCell.title = currentText;
    NSLog(@"new item title is %@", itemInCell.title);
    
    NSLog(@"row of expanded row is %d", self.rowOfExpandedCell);
    self.rowOfExpandedCell = -1;
    
    // Force any text fields that might be being edited to end so the text is stored
    [self.view.window endEditing: YES];
    
    //add funtion here to save item!


    return YES;
}

- (IBAction)addListButton:(id)sender {
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Add a new list"
                                                    message:nil
                                                   delegate:self
                                          cancelButtonTitle:@"cancel"
                                          otherButtonTitles:@"add", nil];
    
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    [alert textFieldAtIndex:0].autocorrectionType = UITextAutocorrectionTypeYes;
    [alert textFieldAtIndex:0].autocapitalizationType = UITextAutocapitalizationTypeSentences;
    
    [alert show];
    
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        NSString *name = [alertView textFieldAtIndex:0].text;
        
        NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
        NSEntityDescription *entity = [[self.fetchedResultsController fetchRequest] entity];
        
        
        Item *newItem = [[Item alloc]initWithEntity:entity insertIntoManagedObjectContext:self.managedObjectContext];
        
        
        NSArray *itemArray = self.fetchedResultsController.fetchedObjects;
        long numberOfResults = [self.fetchedResultsController.fetchedObjects count];
        
        
        if (numberOfResults == 0){
            newItem.order = [NSNumber numberWithLong:16777216];
        }
        else{
            //find the lowest order value in the array of items
            NSSortDescriptor *sortByOrder = [[NSSortDescriptor alloc] initWithKey:@"order" ascending:YES selector:@selector(compare:)];
            NSArray *sortDescriptors = [NSArray arrayWithObject: sortByOrder];
            [itemArray sortedArrayUsingDescriptors:sortDescriptors];
            Item *firstObject = [itemArray objectAtIndex:0];
            long lowestOrder = ([firstObject.order longValue]/2);
            newItem.order = [NSNumber numberWithLong:lowestOrder];
        }
        
        newItem.title = name;
        
        newItem.parent = nil;
        int r = arc4random_uniform(5);
        newItem.list_color = [NSNumber numberWithInt:r];

        
        double timestamp = [[NSDate date] timeIntervalSince1970];
        newItem.itemId = [NSString stringWithFormat:@"%f", timestamp];
        
        NSMutableArray *newArrayOfListsToAdd = [[[NSUserDefaults standardUserDefaults] valueForKey:@"listsToAdd"]mutableCopy];
        [newArrayOfListsToAdd addObject:newItem.itemId];
        [[NSUserDefaults standardUserDefaults] setObject:newArrayOfListsToAdd forKey:@"listsToAdd"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        // Save the context.
        NSError *error = nil;
        if (![context save:&error]) {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
        
        [DoozerSyncManager syncWithServer:self.managedObjectContext];
    }
}

- (void)awakeFromNib {
    [super awakeFromNib];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        self.clearsSelectionOnViewWillAppear = NO;
        self.preferredContentSize = CGSizeMake(320.0, 600.0);
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.rowOfExpandedCell = -1;
    
    // Do any additional setup after loading the view, typically from a nib.
    
    //self.navigationController.navigationBar.barStyle  = UIBarStyleBlackOpaque;
    //self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:0.77 green:0.4 blue:0.68 alpha:1.0];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.rowOfExpandedCell = -1;
    
    [self.tableView reloadData]; // to reload selected cell
    


}

- (void) viewWillDisappear: (BOOL) animated {
    [super viewWillDisappear: animated];
    // Force any text fields that might be being edited to end
    [self.view.window endEditing: YES];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Segues



- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([[segue identifier] isEqualToString:@"showList"]) {
        
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        Item *object = [self.fetchedResultsController objectAtIndexPath:indexPath];
        ListViewController *controller = (ListViewController *)[[segue destinationViewController] topViewController];
        
        controller.managedObjectContext = self.managedObjectContext;
        [controller setDisplayList:object];
        
        controller.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
        controller.navigationItem.leftItemsSupplementBackButton = YES;
        
        UIBarButtonItem *newBackButton =
        [[UIBarButtonItem alloc] initWithTitle:@""
                                         style:UIBarButtonItemStylePlain
                                        target:nil
                                        action:nil];
        [[self navigationItem] setBackBarButtonItem:newBackButton];
        
    }
    if ([[segue identifier] isEqualToString:@"showSettings"]){
        DoozerSettingsManager *controller = segue.destinationViewController;
        controller.managedObjectContext = self.managedObjectContext;
    }
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [[self.fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][section];
    return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];

    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{

    if (self.rowOfExpandedCell == (int)indexPath.row) {
        return 125;
    }else{
        return 75;
    }
}


- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath{

    NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];

    Item *reorderedItem = [self.fetchedResultsController.fetchedObjects objectAtIndex:sourceIndexPath.row];
    NSDecimalNumber *newOrder = nil;
    
    if(destinationIndexPath>sourceIndexPath){
        
        Item *previousItem  = [self.fetchedResultsController.fetchedObjects objectAtIndex:destinationIndexPath.row];
        Item *followingItem  = [self.fetchedResultsController.fetchedObjects objectAtIndex:destinationIndexPath.row+1];
        
        NSDecimalNumber *previousItemOrder = [NSDecimalNumber decimalNumberWithDecimal:[previousItem.order decimalValue]];
        NSDecimalNumber *followingItemOrder = [NSDecimalNumber decimalNumberWithDecimal:[followingItem.order decimalValue]];
        NSDecimalNumber *totalOrder = [followingItemOrder decimalNumberByAdding:previousItemOrder];
        NSDecimalNumber *divisor = [NSDecimalNumber decimalNumberWithString:@"2"];
        newOrder = [totalOrder decimalNumberByDividingBy:divisor];
        reorderedItem.order = newOrder;
    }else{
        
        Item *previousItem  = [self.fetchedResultsController.fetchedObjects objectAtIndex:destinationIndexPath.row-1];
        Item *followingItem  = [self.fetchedResultsController.fetchedObjects objectAtIndex:destinationIndexPath.row];
        
        NSDecimalNumber *previousItemOrder = [NSDecimalNumber decimalNumberWithDecimal:[previousItem.order decimalValue]];
        NSDecimalNumber *followingItemOrder = [NSDecimalNumber decimalNumberWithDecimal:[followingItem.order decimalValue]];
        NSDecimalNumber *totalOrder = [followingItemOrder decimalNumberByAdding:previousItemOrder];
        NSDecimalNumber *divisor = [NSDecimalNumber decimalNumberWithString:@"2"];
        newOrder = [totalOrder decimalNumberByDividingBy:divisor];
        reorderedItem.order = newOrder;
    }
    
    NSString *currentSessionId = [[NSUserDefaults standardUserDefaults] valueForKey:@"UserLoginIdSession"];
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager.requestSerializer setValue:currentSessionId forHTTPHeaderField:@"sessionId"];
    NSString *updateURL = [NSString stringWithFormat:@"https://warm-atoll-6588.herokuapp.com/api/items/%@", reorderedItem.itemId];
    NSDictionary *params = @{
                             @"order": newOrder
                             };
    
    [manager PUT:updateURL parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"JSON: %@", responseObject);
        
        // Save the context.
        NSError *error = nil;
        if (![context save:&error]) {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
    
    [self.tableView reloadData];
    
    
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

-(NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewRowAction *deleteButton = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault title:@"Delete" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath)
                                    {
                                        Item *itemToDelete = [self.fetchedResultsController objectAtIndexPath:indexPath];
                                        
                                        NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
                                        [context deleteObject:[self.fetchedResultsController objectAtIndexPath:indexPath]];
                                        
                                        NSMutableArray *listsToAdd = [[[NSUserDefaults standardUserDefaults] valueForKey:@"listsToAdd"]mutableCopy];
                                        NSMutableArray *newListsToAdd = [[NSMutableArray alloc]init];
                                        int matchCount = 0;
                                        for(id eachElement in listsToAdd){
                                            if ([itemToDelete.itemId isEqualToString:eachElement]){
                                                matchCount +=1;
                                            }else{
                                                [newListsToAdd addObject:eachElement];
                                            }
                                        }
                                        [[NSUserDefaults standardUserDefaults] setObject:newListsToAdd forKey:@"listsToAdd"];
                                        [[NSUserDefaults standardUserDefaults] synchronize];
                                        
                                        if (matchCount == 0){
                                            NSMutableArray *itemsToDelete = [[[NSUserDefaults standardUserDefaults] valueForKey:@"itemsToDelete"]mutableCopy];
                                            [itemsToDelete addObject:itemToDelete.itemId];
                                            [[NSUserDefaults standardUserDefaults] setObject:itemsToDelete forKey:@"itemsToDelete"];
                                            [[NSUserDefaults standardUserDefaults] synchronize];
                                            
                                            NSLog(@"items to delete = %@", itemsToDelete);
                                        }
                                        
                                        // Save the context.
                                        NSError *error = nil;
                                        if (![context save:&error]) {
                                            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
                                            abort();
                                        }
                                        
                                        [DoozerSyncManager syncWithServer:self.managedObjectContext];
                                    }];
    deleteButton.backgroundColor = [UIColor lightGrayColor];
    
    
    UITableViewRowAction *editButton = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault title:@"Edit" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath)
                                     {
                                         
                                         int oldCell = self.rowOfExpandedCell;
                                         self.rowOfExpandedCell = (int)indexPath.row;
                                         
                                         
                                         if (oldCell != -1) {

                                             NSArray *oldPath = [[NSArray alloc]initWithObjects:[NSIndexPath indexPathForRow:oldCell inSection:0], nil];
                                             [self.tableView reloadRowsAtIndexPaths:oldPath withRowAnimation:UITableViewRowAnimationNone];
                                         }
                                         
                                         [self.tableView reloadSections:[[NSIndexSet alloc]initWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];
                                         
                                         //NSArray *path = [[NSArray alloc]initWithObjects:indexPath, nil];
                                    
                                         //[self.tableView reloadRowsAtIndexPaths:path withRowAnimation:UITableViewRowAnimationNone];
                                         
                                         
                                     }];
    editButton.backgroundColor = [UIColor darkGrayColor];
    
    return @[deleteButton, editButton];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    // needs to exist for the "edit" and "delete" buttons on left swipe
    
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    
    [[cell viewWithTag:3] removeFromSuperview];
    [[cell viewWithTag:4] removeFromSuperview];
    [[cell viewWithTag:5] removeFromSuperview];
    
    UITextField *textField = [[UITextField alloc] init];
    textField.tag = 3;
    textField.translatesAutoresizingMaskIntoConstraints = NO;
    [cell.contentView addSubview:textField];
    [cell addConstraint:[NSLayoutConstraint constraintWithItem:textField
                                                     attribute:NSLayoutAttributeLeft
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:cell
                                                     attribute:NSLayoutAttributeLeft
                                                    multiplier:1
                                                      constant:10]];
    
    [cell addConstraint:[NSLayoutConstraint constraintWithItem:textField
                                                     attribute:NSLayoutAttributeTop
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:cell
                                                     attribute:NSLayoutAttributeTop
                                                    multiplier:1
                                                      constant:10]];
    
    [cell addConstraint:[NSLayoutConstraint constraintWithItem:textField
                                                     attribute:NSLayoutAttributeRight
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:cell
                                                     attribute:NSLayoutAttributeRight
                                                    multiplier:1
                                                      constant:10]];
    
    textField.textAlignment = NSTextAlignmentLeft;
    textField.font = [UIFont systemFontOfSize:30];
    textField.textColor = [UIColor whiteColor];
    textField.delegate = self;
    
    UILabel *subTitle = [[UILabel alloc] init];
    subTitle.tag = 4;
    subTitle.translatesAutoresizingMaskIntoConstraints = NO;
    [cell.contentView addSubview:subTitle];
    [cell addConstraint:[NSLayoutConstraint constraintWithItem:subTitle
                                                     attribute:NSLayoutAttributeLeft
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:cell
                                                     attribute:NSLayoutAttributeLeft
                                                    multiplier:1
                                                      constant:10]];
    
    [cell addConstraint:[NSLayoutConstraint constraintWithItem:subTitle
                                                     attribute:NSLayoutAttributeTop
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:cell
                                                     attribute:NSLayoutAttributeTop
                                                    multiplier:1
                                                      constant:45]];
    
    
    subTitle.textAlignment = NSTextAlignmentLeft;
    subTitle.font = [UIFont systemFontOfSize:15];
    subTitle.textColor = [UIColor whiteColor];
    
    UILabel *comingSoon = [[UILabel alloc] init];
    comingSoon.tag = 5;
    comingSoon.translatesAutoresizingMaskIntoConstraints = NO;
    [cell.contentView addSubview:comingSoon];
    [cell addConstraint:[NSLayoutConstraint constraintWithItem:comingSoon
                                                     attribute:NSLayoutAttributeLeft
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:cell
                                                     attribute:NSLayoutAttributeLeft
                                                    multiplier:1
                                                      constant:10]];
    
    [cell addConstraint:[NSLayoutConstraint constraintWithItem:comingSoon
                                                     attribute:NSLayoutAttributeTop
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:cell
                                                     attribute:NSLayoutAttributeTop
                                                    multiplier:1
                                                      constant:90]];
    
    
    comingSoon.textAlignment = NSTextAlignmentCenter;
    comingSoon.font = [UIFont systemFontOfSize:15];
    comingSoon.textColor = [UIColor whiteColor];
    comingSoon.text = @"Color Picker Coming Soon!";
    
    if (self.rowOfExpandedCell == indexPath.row) {
        textField.enabled = YES;
        [textField becomeFirstResponder];
        comingSoon.hidden = NO;
    }else{
        textField.enabled = NO;
        comingSoon.hidden = YES;
    }
    
    
    NSManagedObject *object = [self.fetchedResultsController objectAtIndexPath:indexPath];
    Item *itemInCell = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    cell.showsReorderControl = YES;
    
    textField.text = [[object valueForKey:@"title"] description];
    
    NSNumber *launchCount = [[NSUserDefaults standardUserDefaults] valueForKey:@"NumberOfLaunches"];
    int numKids = 0;
    if ([launchCount intValue] == 0) {
        numKids = itemInCell.children_undone.intValue;
    }else{
        numKids = [CoreDataItemManager findNumberOfUncompletedChildren:itemInCell.itemId:self.managedObjectContext];
    }
    
    subTitle.text = [NSString stringWithFormat:@"%d Items", numKids];
    
    
    int tempInt = [itemInCell.list_color intValue];
    if (self.rowOfExpandedCell != -1) {
        if (self.rowOfExpandedCell == indexPath.row){
            
            UIColor *tempColor = [self returnUIColor:tempInt :1];
            cell.backgroundColor = tempColor;
        
        }else{
            
            UIColor *tempColor = [self returnUIColor:tempInt :0.3];
            cell.backgroundColor = tempColor;
            
        }
    }else{
        UIColor *tempColor = [self returnUIColor:tempInt :1];
        cell.backgroundColor = tempColor;
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    if (self.rowOfExpandedCell == -1) {
        [self performSegueWithIdentifier:@"showList" sender:self];
    }else{
        if (indexPath.row != self.rowOfExpandedCell) {
            //Save item and reload table
            self.rowOfExpandedCell = -1;
            [self.tableView reloadSections:[[NSIndexSet alloc]initWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];
        
        }
    }
    
}

#pragma mark - Fetched results controller

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
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"parent == %@", nil];
    [fetchRequest setPredicate:predicate];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"order" ascending:YES];
    NSArray *sortDescriptors = @[sortDescriptor];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:@"Master"];
    aFetchedResultsController.delegate = self;
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



- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        default:
            return;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    UITableView *tableView = self.tableView;
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView endUpdates];
}

@end
