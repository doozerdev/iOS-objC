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
#import "AFNetworking.h"
#import "CoreDataItemManager.h"
#import "DoozerSettingsManager.h"
#import "DoozerSyncManager.h"
#import "ParentCustomCell.h"
#import "ColorHelper.h"
#import "UpdateItemsOnServer.h"
#import "DeleteItemFromServer.h"

@interface MasterViewController () <UITextFieldDelegate>


@end

@implementation MasterViewController



- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    NSLog(@"text field is beginning editting");
    [textField performSelector:@selector(selectAll:) withObject:nil afterDelay:0.0];

    return YES;
}

// It is important for you to hide the keyboard
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    NSString *currentText = textField.text;
    
    Item *itemInCell = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:self.rowOfExpandedCell inSection:0]];
    
    itemInCell.title = currentText;
    
    self.rowOfExpandedCell = -1;
    
    // Force any text fields that might be being edited to end
    [self.view.window endEditing: YES];
    
    [UpdateItemsOnServer updateThisItem:itemInCell];
    
    [textField resignFirstResponder];
    
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];

    return YES;
}


- (IBAction)addListButton:(id)sender {
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Add a new list"
                                                    message:nil
                                                   delegate:self
                                          cancelButtonTitle:@"cancel"
                                          otherButtonTitles:@"add", nil];
    
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    [alert setTag:1];
    [alert textFieldAtIndex:0].autocorrectionType = UITextAutocorrectionTypeYes;
    [alert textFieldAtIndex:0].autocapitalizationType = UITextAutocapitalizationTypeSentences;
    
    [alert show];
    
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 1) {
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
            
            NSNumber *colorPicker = [[NSUserDefaults standardUserDefaults] valueForKey:@"colorPicker"];
            
            newItem.color = [ColorHelper returnUIColorString:colorPicker.intValue];
            int newColorPickerValue = 1 + colorPicker.intValue;
            if (newColorPickerValue > 4) {
                newColorPickerValue = 0;
            }
            [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:newColorPickerValue] forKey:@"colorPicker"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            
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
    }else if (alertView.tag == 2){
        if (buttonIndex == 1){
                        
            [DeleteItemFromServer deleteThisList:self.itemToDelete];
            self.itemToDelete = nil;
            
        }
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

-(void) redButtonPressed:(UIButton*)button{
    int row = (int)button.tag;
    NSLog(@"red button pressed at row %d", row);

    [self changeListColor:row :0];
}

-(void) yellowButtonPressed:(UIButton*)button{
    int row = (int)button.tag;
    [self changeListColor:row :1];
}

-(void) greenButtonPressed:(UIButton*)button{
    int row = (int)button.tag;
    [self changeListColor:row :2];
}

-(void) blueButtonPressed:(UIButton*)button{
    int row = (int)button.tag;
    [self changeListColor:row :3];
}

-(void) purpleButtonPressed:(UIButton*)button{
    int row = (int)button.tag; 
    [self changeListColor:row :4];
}


-(void)changeListColor:(int)rowIndex :(int)colorIndex{
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:rowIndex inSection:0];
    Item *itemToChangeColor = [self.fetchedResultsController objectAtIndexPath:indexPath];
    itemToChangeColor.color = [ColorHelper returnUIColorString:colorIndex];
   
    [UpdateItemsOnServer updateThisItem:itemToChangeColor];
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
    
    ParentCustomCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    
    Item *itemInCell = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.itemInCell = itemInCell;

    NSNumber *launchCount = [[NSUserDefaults standardUserDefaults] valueForKey:@"NumberOfLaunches"];
    int numKids = 0;
    if ([launchCount intValue] == 0) {
        numKids = itemInCell.children_undone.intValue;
    }else{
        numKids = [CoreDataItemManager findNumberOfUncompletedChildren:itemInCell.itemId];
    }
    
    cell.cellItemTitle.text = itemInCell.title;
    cell.cellItemTitle.textColor = [UIColor whiteColor];
    cell.cellItemTitle.font = [UIFont systemFontOfSize:30];
    
    cell.cellItemSubTitle.text = [NSString stringWithFormat:@"%d Items", numKids];
    cell.cellItemSubTitle.textColor = [UIColor whiteColor];
    cell.cellItemSubTitle.font = [UIFont systemFontOfSize:15];
    
    
    if (self.rowOfExpandedCell == indexPath.row) {
        cell.cellItemTitle.enabled = YES;
        cell.cellItemTitle.delegate = self;
        [cell.cellItemTitle becomeFirstResponder];
        [cell.cellItemTitle performSelector:@selector(selectAll:) withObject:nil afterDelay:0.0];
        cell.RedButton.hidden = NO;
        cell.YellowButton.hidden = NO;
        cell.GreenButton.hidden = NO;
        cell.BlueButton.hidden = NO;
        cell.PurpleButton.hidden = NO;

    }else{
        cell.cellItemTitle.enabled = NO;
        cell.RedButton.hidden = YES;
        cell.YellowButton.hidden = YES;
        cell.GreenButton.hidden = YES;
        cell.BlueButton.hidden = YES;
        cell.PurpleButton.hidden = YES;

    }
    
    if (self.rowOfExpandedCell != -1) {
        if (self.rowOfExpandedCell == indexPath.row){
            
            cell.backgroundColor = [ColorHelper getUIColorFromString:itemInCell.color :1];
            
        }else{
            
            cell.backgroundColor = [ColorHelper getUIColorFromString:itemInCell.color :0.3];
            
        }
    }else{
        cell.backgroundColor = [ColorHelper getUIColorFromString:itemInCell.color :1];
    }
    
    cell.RedButton.tag = indexPath.row;
    [cell.RedButton addTarget:self action:@selector(redButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    cell.RedButton.backgroundColor = [ColorHelper getUIColorFromString:[ColorHelper returnUIColorString:0] :1];
    [cell.RedButton.layer setBorderWidth:0];

    cell.YellowButton.tag = indexPath.row;
    [cell.YellowButton addTarget:self action:@selector(yellowButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    cell.YellowButton.backgroundColor = [ColorHelper getUIColorFromString:[ColorHelper returnUIColorString:1] :1];
    [cell.YellowButton.layer setBorderWidth:0];

    cell.GreenButton.tag = indexPath.row;
    [cell.GreenButton addTarget:self action:@selector(greenButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    cell.GreenButton.backgroundColor = [ColorHelper getUIColorFromString:[ColorHelper returnUIColorString:2] :1];
    [cell.GreenButton.layer setBorderWidth:0];

    cell.BlueButton.tag = indexPath.row;
    [cell.BlueButton addTarget:self action:@selector(blueButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    cell.BlueButton.backgroundColor = [ColorHelper getUIColorFromString:[ColorHelper returnUIColorString:3] :1];
    [cell.BlueButton.layer setBorderWidth:0];

    cell.PurpleButton.tag = indexPath.row;
    [cell.PurpleButton addTarget:self action:@selector(purpleButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    cell.PurpleButton.backgroundColor = [ColorHelper getUIColorFromString:[ColorHelper returnUIColorString:4] :1];
    [cell.PurpleButton.layer setBorderWidth:0];

    
    if ([itemInCell.color isEqualToString:@"255,107,107,1"]) {
        [cell.RedButton.layer setBorderWidth:3.0];
        [cell.RedButton.layer setBorderColor:[[UIColor whiteColor] CGColor]];
    }else if([itemInCell.color isEqualToString:@"236,183,0,1"]){
        [cell.YellowButton.layer setBorderWidth:3.0];
        [cell.YellowButton.layer setBorderColor:[[UIColor whiteColor] CGColor]];
    }else if([itemInCell.color isEqualToString:@"134,194,63,1"]){
        [cell.GreenButton.layer setBorderWidth:3.0];
        [cell.GreenButton.layer setBorderColor:[[UIColor whiteColor] CGColor]];
    }else if([itemInCell.color isEqualToString:@"46,179,193,1"]){
        [cell.BlueButton.layer setBorderWidth:3.0];
        [cell.BlueButton.layer setBorderColor:[[UIColor whiteColor] CGColor]];
    }else if([itemInCell.color isEqualToString:@"198,99,175,1"]){
        [cell.PurpleButton.layer setBorderWidth:3.0];
        [cell.PurpleButton.layer setBorderColor:[[UIColor whiteColor] CGColor]];
    }

    return cell;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{


    //NSLog(@"in height for row at index path");

    if (self.rowOfExpandedCell == indexPath.row) {
        //NSLog(@"setting height to 125");
        return 125;
    }else{
        //NSLog(@"setting height to 75");
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
                                        
                                        NSString *message = [NSString stringWithFormat:@"Are you sure you want to delete '%@' and all tasks in the list?", itemToDelete.title];
                                        
                                        UIAlertView *deleteList = [[UIAlertView alloc] initWithTitle:message
                                                                                             message:nil
                                                                                            delegate:self
                                                                                   cancelButtonTitle:@"Cancel"
                                                                                   otherButtonTitles:@"Delete", nil];
                                        
                                        deleteList.alertViewStyle = UIAlertViewStyleDefault;
                                        [deleteList setTag:2];
                                        self.itemToDelete = itemToDelete;
                                        [deleteList show];
                                        
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
                                         
                                     }];
    editButton.backgroundColor = [UIColor darkGrayColor];
    
    return @[deleteButton, editButton];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    // needs to exist for the "edit" and "delete" buttons on left swipe
    
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
            
            NSLog(@"NSFectchedResultsChangeUpdate");
            
            [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            //[self configureCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
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
