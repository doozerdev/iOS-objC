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
    
    self.itemNameTextField.delegate = self;
    
    self.detailViewController = (DetailViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
    
    UISwipeGestureRecognizer *recognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(leftSwipe:)];
    [recognizer setDirection:(UISwipeGestureRecognizerDirectionLeft)];
    [self.tableView addGestureRecognizer:recognizer];
    
    recognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(rightSwipe:)];
    recognizer.delegate = self;
    [recognizer setDirection:(UISwipeGestureRecognizerDirectionRight)];
    [self.tableView addGestureRecognizer:recognizer];
    
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc]
                                               initWithTarget:self action:@selector(longPressGestureRecognized:)];
    [self.tableView addGestureRecognizer:longPress];
    
}

- (IBAction)longPressGestureRecognized:(id)sender {
    
    UILongPressGestureRecognizer *longPress = (UILongPressGestureRecognizer *)sender;
    UIGestureRecognizerState state = longPress.state;
    
    CGPoint location = [longPress locationInView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:location];
    //_superOriginalIndex = NULL;
    
    static UIView       *snapshot = nil;        ///< A snapshot of the row user is moving.
    static NSIndexPath  *sourceIndexPath = nil; ///< Initial index path, where gesture begins.
    
    switch (state) {
        case UIGestureRecognizerStateBegan: {
            if (indexPath) {
                _superOriginalIndex = [self.tableView indexPathForRowAtPoint:location];
                NSLog(@"here's where we think the item started = %ld", (long)_superOriginalIndex.row);
                
                sourceIndexPath = indexPath;
                
                UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
                
                // Take a snapshot of the selected row using helper method.
                snapshot = [self customSnapshoFromView:cell];
                
                // Add the snapshot as subview, centered at cell's center...
                __block CGPoint center = cell.center;
                snapshot.center = center;
                snapshot.alpha = 0.0;
                [self.tableView addSubview:snapshot];
                [UIView animateWithDuration:0.25 animations:^{
                    
                    // Offset for gesture location.
                    center.y = location.y;
                    snapshot.center = center;
                    snapshot.transform = CGAffineTransformMakeScale(1.05, 1.05);
                    snapshot.alpha = 0.98;
                    cell.alpha = 0.0;
                    
                } completion:^(BOOL finished) {
                    
                    cell.hidden = YES;
                    
                }];
            }
            break;
        }
            
        case UIGestureRecognizerStateChanged: {
            CGPoint center = snapshot.center;
            center.y = location.y;
            snapshot.center = center;
            
            // Is destination valid and is it different from source?
            if (indexPath && ![indexPath isEqual:sourceIndexPath]) {
                
                // ... update data source.
                //[self.objects exchangeObjectAtIndex:indexPath.row withObjectAtIndex:sourceIndexPath.row];
    
                
                // ... move the rows.
                [self.tableView moveRowAtIndexPath:sourceIndexPath toIndexPath:indexPath];
                
                // ... and update source so it is in sync with UI changes.
                sourceIndexPath = indexPath;
            }
            break;
        }
            
        case UIGestureRecognizerStateEnded: {
            
            Item *reorderedItem = [self.fetchedResultsController.fetchedObjects objectAtIndex:_superOriginalIndex.row];;
            
            NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
            
            NSUInteger numberOfObjects = [self.fetchedResultsController.fetchedObjects count];
            NSLog(@"total number of items on list = %lu", numberOfObjects);
            
            
            NSLog(@"super Original Index = %ld", (long)_superOriginalIndex.row);
            NSLog(@"Index = %ld", (long)indexPath.row);
            Item *previousItem = nil;
            Item *followingItem  = nil;
            
            if(_superOriginalIndex.row < indexPath.row){
                if (indexPath.row == (numberOfObjects - 1)) {
                    NSLog(@"Moving to bottom of list, then crash!");
                    Item *originalLastItem = [self.fetchedResultsController.fetchedObjects objectAtIndex:indexPath.row];
                    int newItemNewOrder = originalLastItem.order.intValue + 1048576;
            
                    NSLog(@"Here's the new last item order = %d", newItemNewOrder);
                    reorderedItem.order =  [NSNumber numberWithInt:newItemNewOrder];
                    
                }else{
                    NSLog(@"entered FIRST case");
                    previousItem  = [self.fetchedResultsController.fetchedObjects objectAtIndex:indexPath.row];
                    followingItem  = [self.fetchedResultsController.fetchedObjects objectAtIndex:indexPath.row+1];
                    
                    int previousItemOrder = [previousItem.order intValue];
                    int followingItemOrder = [followingItem.order intValue];
                    int newOrder = (previousItemOrder + followingItemOrder)/2;
                    reorderedItem.order = [NSNumber numberWithInt:newOrder];
                }
                
            }else{
                if (indexPath.row == 0) {
                    NSLog(@"Moving to top of list!");
                    Item *originalFirstItem = [self.fetchedResultsController.fetchedObjects objectAtIndex:indexPath.row];
                    int newItemNewOrder = originalFirstItem.order.intValue / 2;
            
                    NSLog(@"Here's the new first item order = %d", newItemNewOrder);
                    reorderedItem.order =  [NSNumber numberWithInt:newItemNewOrder];
                }else{
                
                    NSLog(@"entered SECOND case");
                    previousItem  = [self.fetchedResultsController.fetchedObjects objectAtIndex:indexPath.row-1];
                    followingItem  = [self.fetchedResultsController.fetchedObjects objectAtIndex:indexPath.row];
                
                    int previousItemOrder = [previousItem.order intValue];
                    int followingItemOrder = [followingItem.order intValue];
                    int newOrder = (previousItemOrder + followingItemOrder)/2;
                    reorderedItem.order = [NSNumber numberWithInt:newOrder];
                }
            }
            
            NSLog(@"Previous Item = %@", previousItem.title);
            NSLog(@"reordered item name = %@", reorderedItem.title);
            NSLog(@"following Item = %@", followingItem.title);
        
            NSString *currentSessionId = [[NSUserDefaults standardUserDefaults] valueForKey:@"UserLoginIdSession"];
            AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
            [manager.requestSerializer setValue:currentSessionId forHTTPHeaderField:@"sessionId"];
            
            
            NSString *updateURL = [NSString stringWithFormat:@"https://warm-atoll-6588.herokuapp.com/api/items/%@", reorderedItem.itemId];
            
            NSDictionary *params = @{@"order": reorderedItem.order};
            
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
            
            // Save the context.
            NSError *error = nil;
            if (![context save:&error]) {
                NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
                abort();
            }

            
            [self.tableView reloadData];
            
        }
            
        default: {
            // Clean up.
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:sourceIndexPath];
            cell.hidden = NO;
            cell.alpha = 0.0;
            
            [UIView animateWithDuration:0.25 animations:^{
                
                snapshot.center = cell.center;
                snapshot.transform = CGAffineTransformIdentity;
                snapshot.alpha = 0.0;
                cell.alpha = 1.0;
                
            } completion:^(BOOL finished) {
                
                sourceIndexPath = nil;
                [snapshot removeFromSuperview];
                snapshot = nil;
                
            }];
            
            break;
        }
    }

}


- (void)leftSwipe:(UISwipeGestureRecognizer *)gestureRecognizer
{
    //do you left swipe stuff here.
    NSLog(@"left swipe happened");
}

- (void)rightSwipe:(UISwipeGestureRecognizer *)gestureRecognizer
{
    
    NSArray *listArray = [self.fetchedResultsController fetchedObjects];
    NSMutableArray *completedItemOrderValues = [[NSMutableArray alloc] init];
    NSMutableArray *allItemOrderValues = [[NSMutableArray alloc] init];

    for (id eachElement in listArray){
        Item *theItem = eachElement;
        [allItemOrderValues addObject:theItem.order];
        if ([theItem.done intValue] == 1) {
            [completedItemOrderValues addObject:theItem.order];
        }
    }
    
    int completedMinOrder = [[completedItemOrderValues valueForKeyPath:@"@min.intValue"] intValue];
    int maxItemOrder = [[allItemOrderValues valueForKeyPath:@"@max.intValue"] intValue];
    
    CGPoint location = [gestureRecognizer locationInView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:location];

    NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
    Item *itemToToggleComplete = [self.fetchedResultsController.fetchedObjects objectAtIndex:indexPath.row];
 
    NSNumber *num = [NSNumber numberWithInt:completedMinOrder];
    
    int indexOfFirstCompleted = 0;
    
    if ([num intValue] == 0) {
        int newOrderForCompletedItem = maxItemOrder + 10000000;
        NSNumber *orderForCompleted = [NSNumber numberWithInt:newOrderForCompletedItem];
        itemToToggleComplete.order = orderForCompleted;
        
    }
    else{
        int loopcount = 0;
        
        for(id eachElement in allItemOrderValues){
            NSNumber *placeholder = eachElement;
            int value = [placeholder intValue];
            if (value == completedMinOrder)
            {
                indexOfFirstCompleted = loopcount;
            }
            loopcount ++;
        }
        
        int indexOfLastUncompleted = indexOfFirstCompleted - 1;
        NSNumber *monkey = [allItemOrderValues objectAtIndex:indexOfLastUncompleted];
        int orderValOfLastUncompleted = [monkey intValue];
            
        int newOrderForCompletedItem = ((completedMinOrder - orderValOfLastUncompleted)/2)+orderValOfLastUncompleted;
        NSNumber *orderForCompleted = [NSNumber numberWithInt:newOrderForCompletedItem];
        NSLog(@"updating order to = %@", orderForCompleted);
        itemToToggleComplete.order = orderForCompleted;
    }
    
    NSString *orderAfterToggling = itemToToggleComplete.order.stringValue;
    
    NSDictionary *params = nil;
    if([itemToToggleComplete.done intValue] == 0){
        itemToToggleComplete.done = [NSNumber numberWithBool:true];
        params= @{@"done": @"true", @"order": orderAfterToggling};
        
        
    }else{
        itemToToggleComplete.done = [NSNumber numberWithBool:false];
        params= @{@"done": @"false", @"order": orderAfterToggling};
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
    
    if (textField.text.length > 0) {
        [self insertNewObject:nil];
    }
    else{
        NSLog(@"they're not typing anything");
    }
    [textField resignFirstResponder];

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
    }else{
        cell.textLabel.textColor = [UIColor blackColor];
    }
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



#pragma mark - Helper methods

/** @brief Returns a customized snapshot of a given view. */
- (UIView *)customSnapshoFromView:(UIView *)inputView {
    
    // Make an image from the input view.
    UIGraphicsBeginImageContextWithOptions(inputView.bounds.size, NO, 0);
    [inputView.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    // Create an image view.
    UIView *snapshot = [[UIImageView alloc] initWithImage:image];
    snapshot.layer.masksToBounds = NO;
    snapshot.layer.cornerRadius = 0.0;
    snapshot.layer.shadowOffset = CGSizeMake(-5.0, 0.0);
    snapshot.layer.shadowRadius = 5.0;
    snapshot.layer.shadowOpacity = 0.4;
    
    return snapshot;
}


@end

