//
//  AddItemViewController.m
//  Doozer
//
//  Created by Daniel Apone on 7/20/15.
//  Copyright © 2015 Daniel Apone. All rights reserved.
//

#import "AddItemViewController.h"
#import "AppDelegate.h"
#import "ParentCustomCell.h"
#import "ColorHelper.h"
#import "MasterViewController.h"
#import "AddItemsToServer.h"

@interface AddItemViewController ()

@end

@implementation AddItemViewController

- (IBAction)itemTitleText:(id)sender {
    
    NSLog(@"here's the test in item title");
    
}

- (IBAction)pressedCancelButton:(id)sender {
    [self.view.window endEditing: YES];

    [self dismissViewControllerAnimated:YES completion:nil];

}
- (IBAction)addButtonPressed:(id)sender {
    
    [self createItem];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    self.showAllLists = NO;
    // Do any additional setup after loading the view.
    self.selectedList = [self.fetchedResultsController.fetchedObjects objectAtIndex:0];
    UITextField *newItemTitle = (UITextField *)[self.view viewWithTag:888];
    [newItemTitle becomeFirstResponder];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    NSLog(@"text field is beginning editting");
    
    return YES;
}


// It is important for you to hide the keyboard
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{

    [self createItem];
    
    return YES;
}

- (void)createItem {
    
    UITextField *newItemTitle = (UITextField *)[self.view viewWithTag:888];
    [self.view.window endEditing: YES];
    [newItemTitle resignFirstResponder];
    
    NSLog(@"title fo item to create is == %@", newItemTitle);
    
    if (newItemTitle.text.length > 0) {
    
        AppDelegate* appDelegate = [AppDelegate sharedAppDelegate];
        NSManagedObjectContext* context = appDelegate.managedObjectContext;
        
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"ItemRecord" inManagedObjectContext:context];
        [fetchRequest setEntity:entity];
        
        [fetchRequest setFetchBatchSize:20];
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"parent == %@", self.selectedList.itemId];
        [fetchRequest setPredicate:predicate];
        
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"order" ascending:YES];
        NSArray *sortDescriptors = @[sortDescriptor];
        [fetchRequest setSortDescriptors:sortDescriptors];
        
        NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:context sectionNameKeyPath:nil cacheName:@"Master3"];
        [NSFetchedResultsController deleteCacheWithName:@"Master3"];
        
        NSError *error = nil;
        if (![aFetchedResultsController performFetch:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
        
        Item *newItem = [[Item alloc]initWithEntity:entity insertIntoManagedObjectContext:context];
        
        NSArray *itemsOnSelectedList = aFetchedResultsController.fetchedObjects;
        Item *firstItemOnList = [itemsOnSelectedList objectAtIndex:0];
        int newItemOrder = firstItemOnList.order.intValue / 2;
        newItem.order = [NSNumber numberWithInt:newItemOrder];
        newItem.title = newItemTitle.text;
        
        newItem.done = 0;
        newItem.notes = @" ";
        
        newItem.parent = self.selectedList.itemId;
        
        double timestamp = [[NSDate date] timeIntervalSince1970];
        newItem.itemId = [NSString stringWithFormat:@"%f", timestamp];
        
        [AddItemsToServer addThisItem:newItem];
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];

}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Number of rows is the number of time zones in the region for the specified section.
    NSInteger rowCount = [self.fetchedResultsController.fetchedObjects count];
    return rowCount;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if (self.showAllLists) {
        return 40;
    }else{
        if (indexPath.row == 0) {
            return 40;
        }else{
            return 0;
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *MyIdentifier = @"CellsOfLists";
    ParentCustomCell *cell = [tableView dequeueReusableCellWithIdentifier:MyIdentifier];
    if (cell == nil) {
        cell = [[ParentCustomCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:MyIdentifier];
    }
    
    //Item *itemInCell = [[Item alloc]init];

    Item *itemInCell = [self.fetchedResultsController objectAtIndexPath:indexPath];

    if (indexPath.row == 0) {
        cell.textLabel.text = self.selectedList.title;
    }else{
        cell.textLabel.text = itemInCell.title;
    }
    cell.textLabel.textColor = [ColorHelper getUIColorFromString:itemInCell.color :1];

    cell.textLabel.textAlignment = NSTextAlignmentLeft;
    cell.textLabel.font = [UIFont fontWithName:@"Avenir" size:20];
    
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.selectedList = [self.fetchedResultsController objectAtIndexPath:indexPath];
    UITextField *typeField = (UITextField *)[self.view viewWithTag:888];


    if (self.showAllLists) {
        self.showAllLists = NO;
        typeField.userInteractionEnabled = YES;
        typeField.hidden = NO;

    }else {
        self.showAllLists = YES;
        typeField.userInteractionEnabled = NO;
        typeField.hidden = YES;

    }

    [tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];
    
    
    
    
    if (self.showAllLists) {
        [typeField resignFirstResponder];
        [self.view endEditing:YES];
    }else{
        [typeField becomeFirstResponder];
    }
    
    
    
}


 #pragma mark - Segues
 
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 
     if ([[segue identifier] isEqualToString:@"unwindToMaster"]) {
         NSLog(@"prepare for segue unwind to master");
     }
 }



- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    
    AppDelegate* appDelegate = [AppDelegate sharedAppDelegate];
    NSManagedObjectContext* context = appDelegate.managedObjectContext;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"ItemRecord" inManagedObjectContext:context];
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
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:context sectionNameKeyPath:nil cacheName:@"Master2"];
    //aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;
    [NSFetchedResultsController deleteCacheWithName:@"Master2"];
    
    
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
