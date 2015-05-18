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




@interface MasterViewController ()

@property (weak, nonatomic) IBOutlet UITextField *listNameTextField;

@end

@implementation MasterViewController

- (void)awakeFromNib {
    [super awakeFromNib];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        self.clearsSelectionOnViewWillAppear = NO;
        self.preferredContentSize = CGSizeMake(320.0, 600.0);
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
    
    self.listNameTextField.delegate = self;
    
    self.listViewController = (ListViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
    
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self insertNewObject:nil];
    return YES;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)insertNewObject:(id)sender {
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
    
    newItem.itemName = self.listNameTextField.text;
    
    newItem.completed = [NSNumber numberWithLong:0];
    
    newItem.createdDate = [NSDate date];
    
    int r = arc4random_uniform(1000);
    newItem.itemId = [NSNumber numberWithLong:r];

    newItem.parentId = nil;
    
    
    
    
    self.listNameTextField.text = nil;
    
    // Save the context.
    NSError *error = nil;
    if (![context save:&error]) {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
}

#pragma mark - Segues



- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([[segue identifier] isEqualToString:@"showList"]) {
        
        
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        Item *object = [[self fetchedResultsController] objectAtIndexPath:indexPath];
        ListViewController *controller = (ListViewController *)[[segue destinationViewController] topViewController];
        
        controller.managedObjectContext = self.managedObjectContext;
        [controller setDisplayList:object];
        
        controller.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
        controller.navigationItem.leftItemsSupplementBackButton = YES;
        
    }
    if ([[segue identifier] isEqualToString:@"showLoginFromMaster"]) {
        
        LoginViewController *controller = (LoginViewController *)[segue destinationViewController];
        
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

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath{

    NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];

    
    Item *reorderedItem = [self.fetchedResultsController.fetchedObjects objectAtIndex:sourceIndexPath.row];
    
    if(destinationIndexPath>sourceIndexPath){
        
        Item *previousItem  = [self.fetchedResultsController.fetchedObjects objectAtIndex:destinationIndexPath.row];
        Item *followingItem  = [self.fetchedResultsController.fetchedObjects objectAtIndex:destinationIndexPath.row+1];
        
        NSDecimalNumber *previousItemOrder = [NSDecimalNumber decimalNumberWithDecimal:[previousItem.order decimalValue]];
        NSDecimalNumber *followingItemOrder = [NSDecimalNumber decimalNumberWithDecimal:[followingItem.order decimalValue]];
        NSDecimalNumber *totalOrder = [followingItemOrder decimalNumberByAdding:previousItemOrder];
        NSDecimalNumber *divisor = [NSDecimalNumber decimalNumberWithString:@"2"];
        NSDecimalNumber *newOrder = [totalOrder decimalNumberByDividingBy:divisor];
        reorderedItem.order = newOrder;
    }else{
        
        Item *previousItem  = [self.fetchedResultsController.fetchedObjects objectAtIndex:destinationIndexPath.row-1];
        Item *followingItem  = [self.fetchedResultsController.fetchedObjects objectAtIndex:destinationIndexPath.row];
        
        NSDecimalNumber *previousItemOrder = [NSDecimalNumber decimalNumberWithDecimal:[previousItem.order decimalValue]];
        NSDecimalNumber *followingItemOrder = [NSDecimalNumber decimalNumberWithDecimal:[followingItem.order decimalValue]];
        NSDecimalNumber *totalOrder = [followingItemOrder decimalNumberByAdding:previousItemOrder];
        NSDecimalNumber *divisor = [NSDecimalNumber decimalNumberWithString:@"2"];
        NSDecimalNumber *newOrder = [totalOrder decimalNumberByDividingBy:divisor];
        reorderedItem.order = newOrder;
        
    }
    
    
    
    
    
    
    // Save the context.
    NSError *error = nil;
    if (![context save:&error]) {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    [self.tableView reloadData];
    
    
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
        [context deleteObject:[self.fetchedResultsController objectAtIndexPath:indexPath]];
            
        NSError *error = nil;
        if (![context save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    
    NSManagedObject *object = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    cell.showsReorderControl = YES;
    

    NSNumber *completedNumber = [object valueForKey:@"completed"];
    BOOL B = [completedNumber boolValue];
    

    cell.textLabel.text = [[object valueForKey:@"itemName"] description];
    
    
    if (B) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
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
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"parentId == %@", nil];
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

/*
// Implementing the above methods to update the table view in response to individual changes may have performance implications if a large number of changes are made simultaneously. If this proves to be an issue, you can instead just implement controllerDidChangeContent: which notifies the delegate that all section and object changes have been processed. 
 
 - (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    // In the simplest, most efficient, case, reload the table view.
    [self.tableView reloadData];
}
 */

@end
