//
//  ListViewController.m
//  Doozer
//
//  Created by Daniel Apone on 5/3/15.
//  Copyright (c) 2015 Daniel Apone. All rights reserved.
//

#import "ListViewController.h"
#import "DetailViewController.h"
#import "Item.h"
#import "AFNetworking.h"



@interface ListViewController ()

@property (weak, nonatomic) IBOutlet UITextField *itemNameTextField;


@end

@implementation ListViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
    
    self.itemNameTextField.delegate = self;
    
    self.detailViewController = (DetailViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
    
    UISwipeGestureRecognizer *recognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(leftSwipe:)];
    [recognizer setDirection:(UISwipeGestureRecognizerDirectionLeft)];
    [self.tableView addGestureRecognizer:recognizer];
    
    recognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(rightSwipe:)];
    recognizer.delegate = self;
    [recognizer setDirection:(UISwipeGestureRecognizerDirectionRight)];
    [self.tableView addGestureRecognizer:recognizer];
    
}

- (void)leftSwipe:(UISwipeGestureRecognizer *)gestureRecognizer
{
    //do you left swipe stuff here.
}

- (void)rightSwipe:(UISwipeGestureRecognizer *)gestureRecognizer
{
    
    NSArray *listArray = [self.fetchedResultsController fetchedObjects];
    NSLog(@"here's the array = %@", listArray);
    
    
    NSMutableArray *completedItemOrderValues = [[NSMutableArray alloc] init];
    NSMutableArray *allItemOrderValues = [[NSMutableArray alloc] init];
    
    for (id eachElement in listArray){
        Item *theItem = eachElement;
        [allItemOrderValues addObject:theItem.order];
        if ([theItem.done intValue] == 1) {
            [completedItemOrderValues addObject:theItem.order];
        }
    }
    
    NSLog(@"previously completed Item order Values = %@", completedItemOrderValues);
    NSLog(@"all Item order Values = %@", allItemOrderValues);
    
    
    CGPoint location = [gestureRecognizer locationInView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:location];
    NSLog(@"here's the index path = %@", indexPath);

    NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
    Item *itemToToggleComplete = [self.fetchedResultsController.fetchedObjects objectAtIndex:indexPath.row];
        
    NSDictionary *params = nil;
    if([itemToToggleComplete.done intValue] == 0){
        itemToToggleComplete.done = [NSNumber numberWithBool:true];
        params= @{@"done": @"true"};
    }else{
        itemToToggleComplete.done = [NSNumber numberWithBool:false];
        params= @{@"done": @"false"};
    }
        
    NSString *currentSessionId = [[NSUserDefaults standardUserDefaults] valueForKey:@"UserLoginIdSession"];
    NSLog(@"current session ID = %@", currentSessionId);
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager.requestSerializer setValue:currentSessionId forHTTPHeaderField:@"sessionId"];
        
    NSString *updateURL = [NSString stringWithFormat:@"https://warm-atoll-6588.herokuapp.com/api/items/%@", itemToToggleComplete.itemId];
        
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
    

        
        
        
    }


- (void)setDisplayList:(id)newDisplayList {
    if (_displayList != newDisplayList) {
        _displayList = newDisplayList;
        
        // Update the view.
        [self configureView];
    }
}

- (void)configureView {
    // Update the user interface for the detail item.
    if (self.displayList) {
        
        Item *displayThisList = self.displayList;
        
        NSString *superMonkey = displayThisList.title;
        superMonkey = nil;
    }
}

- (void)awakeFromNib {
    [super awakeFromNib];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        self.clearsSelectionOnViewWillAppear = NO;
        self.preferredContentSize = CGSizeMake(320.0, 600.0);
    }
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
    
    newItem.title = self.itemNameTextField.text;
    
    newItem.done = 0;
    
    Item *parentList = self.displayList;
    
    newItem.parent = parentList.itemId;
    
    self.itemNameTextField.text = nil;
    
    NSString *currentSessionId = [[NSUserDefaults standardUserDefaults] valueForKey:@"UserLoginIdSession"];
    NSLog(@"current session ID = %@", currentSessionId);
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager.requestSerializer setValue:currentSessionId forHTTPHeaderField:@"sessionId"];
    
    NSLog(@"current parent list = %@", parentList.itemId);
    
    NSDictionary *params = @{@"title": newItem.title, @"parent": parentList.itemId};
    [manager POST:@"https://warm-atoll-6588.herokuapp.com/api/items" parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"JSON: %@", responseObject);
        
        NSDictionary *serverResponse = (NSDictionary *)responseObject;
        NSString *newItemId = [serverResponse objectForKey:@"id"];
        newItem.itemId = newItemId;
        
        // Save the context.
        NSError *error = nil;
        if (![context save:&error]) {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"showItem"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        NSManagedObject *object = [[self fetchedResultsController] objectAtIndexPath:indexPath];
        
        DetailViewController *controller = (DetailViewController *)[[segue destinationViewController] topViewController];
        controller.managedObjectContext = self.managedObjectContext;
        [controller setDetailItem:object];
        
        controller.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
        controller.navigationItem.leftItemsSupplementBackButton = YES;
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
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"itemCell" forIndexPath:indexPath];
    [self configureCell:cell atIndexPath:indexPath];
    
    return cell;
}


- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    NSManagedObject *object = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.showsReorderControl = YES;
    cell.textLabel.text = [object valueForKey:@"title"];
    NSString *done = [object valueForKey:@"done"];
    
    if ([done intValue] == 1) {
        cell.textLabel.textColor = [UIColor lightGrayColor];
    }
}


- (void)checkButtonTapped:(id)sender
{
    CGPoint buttonPosition = [sender convertPoint:CGPointZero toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:buttonPosition];
    if (indexPath != nil)
    {
        NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
        Item *itemToToggleComplete = [self.fetchedResultsController.fetchedObjects objectAtIndex:indexPath.row];
        
        NSDictionary *params = nil;
        if([itemToToggleComplete.done intValue] == 0){
            itemToToggleComplete.done = [NSNumber numberWithBool:true];
            params= @{@"done": @"true"};
        }else{
            itemToToggleComplete.done = [NSNumber numberWithBool:false];
            params= @{@"done": @"false"};
        }
        
        NSString *currentSessionId = [[NSUserDefaults standardUserDefaults] valueForKey:@"UserLoginIdSession"];
        NSLog(@"current session ID = %@", currentSessionId);
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        [manager.requestSerializer setValue:currentSessionId forHTTPHeaderField:@"sessionId"];
        
        NSString *updateURL = [NSString stringWithFormat:@"https://warm-atoll-6588.herokuapp.com/api/items/%@", itemToToggleComplete.itemId];
        
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
    NSLog(@"current session ID = %@", currentSessionId);
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager.requestSerializer setValue:currentSessionId forHTTPHeaderField:@"sessionId"];
    
    
    NSString *updateURL = [NSString stringWithFormat:@"https://warm-atoll-6588.herokuapp.com/api/items/%@", reorderedItem.itemId];
    NSLog(@"here's the update URL = %@", updateURL);
    
    NSDictionary *params = @{@"order": newOrder};
    
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


- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {

        NSString *currentSessionId = [[NSUserDefaults standardUserDefaults] valueForKey:@"UserLoginIdSession"];
        NSLog(@"current session ID = %@", currentSessionId);
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        [manager.requestSerializer setValue:currentSessionId forHTTPHeaderField:@"sessionId"];
    
        Item *itemToDelete = [self.fetchedResultsController objectAtIndexPath:indexPath];
        NSString *itemToDeleteId = itemToDelete.itemId;
        NSLog(@"here's the item to delete = %@", itemToDeleteId);
        
        NSString *deleteURL = [NSString stringWithFormat:@"https://warm-atoll-6588.herokuapp.com/api/items/%@", itemToDeleteId];
        
        NSDictionary *params = @{@"archive": @"true"};

        [manager PUT:deleteURL parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"JSON: %@", responseObject);
            NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
            [context deleteObject:[self.fetchedResultsController objectAtIndexPath:indexPath]];
                
            // Save the context.
            NSError *error = nil;
            if (![context save:&error]) {
                NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
                abort();
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Error: %@", error);
        }];
        
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
    
    Item *parentItem = self.displayList;
    NSString *currentParentId = parentItem.itemId;
    NSLog(@"NSFetchedResultsController current parent ID = %@", currentParentId);
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"parent == %@", currentParentId];
    [fetchRequest setPredicate:predicate];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"order" ascending:YES];
    NSArray *sortDescriptors = @[sortDescriptor];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:@"List"];
    aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;
    [NSFetchedResultsController deleteCacheWithName:@"List"];
    
    
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
