//
//  ListViewController.m
//  Doozer
//
//  Created by Daniel Apone on 5/3/15.
//  Copyright (c) 2015 Daniel Apone. All rights reserved.
//

#import "ListViewController.h"
#import "ItemViewController.h"
#import "Item.h"
#import "AFNetworking.h"
#import "DoozerSyncManager.h"


@interface ListViewController ()


@end

@implementation ListViewController

- (UIColor *)returnUIColor:(int)numPicker{
    UIColor *returnValue = nil;
    
    if (numPicker == 0) {
        returnValue = [UIColor colorWithRed:46/255. green:179/255. blue:193/255. alpha:1]; //blue
    }
    else if (numPicker == 1){
        returnValue = [UIColor colorWithRed:134/255. green:194/255. blue:63/255. alpha:1]; //green
    }
    else if (numPicker == 2){
        returnValue = [UIColor colorWithRed:255/255. green:107/255. blue:107/255. alpha:1]; //red
    }
    else if (numPicker == 3){
        returnValue = [UIColor colorWithRed:198/255. green:99/255. blue:175/255. alpha:1]; //purple
    }
    else if (numPicker == 4){
        returnValue = [UIColor colorWithRed:236/255. green:183/255. blue:0/255. alpha:1]; //yellow
    }
    else{
        returnValue = [UIColor whiteColor];
    }
    
    return returnValue;
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    Item *listForTitle = self.displayList;
    
    UIColor *tempColor = [self returnUIColor:[listForTitle.list_color intValue]];
    self.view.backgroundColor = tempColor;
    
    //self.navigationController.navigationBar.barStyle  = UIBarStyleBlackTranslucent;
    //self.navigationController.navigationBar.barTintColor = tempColor;
    
    self.navigationItem.title = listForTitle.title;
    //self.detailViewController = (DetailViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
    
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

- (IBAction)addItemButton:(id)sender {
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Add a new item"
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
        NSArray *itemArray = [self.fetchedResultsController fetchedObjects];
        long numberOfResults = [itemArray count];
        
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
        
        newItem.done = 0;
        newItem.notes = @" ";
        
        Item *parentList = self.displayList;
        
        newItem.parent = parentList.itemId;
        
        double timestamp = [[NSDate date] timeIntervalSince1970];
        newItem.itemId = [NSString stringWithFormat:@"%f", timestamp];
        
        NSMutableArray *newArrayOfItemsToAdd = [[[NSUserDefaults standardUserDefaults] valueForKey:@"itemsToAdd"]mutableCopy];
        [newArrayOfItemsToAdd addObject:newItem.itemId];
        [[NSUserDefaults standardUserDefaults] setObject:newArrayOfItemsToAdd forKey:@"itemsToAdd"];
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


- (IBAction)longPressGestureRecognized:(id)sender {
    
    UILongPressGestureRecognizer *longPress = (UILongPressGestureRecognizer *)sender;
    UIGestureRecognizerState state = longPress.state;
    
    CGPoint location = [longPress locationInView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:location];
    
    static UIView       *snapshot = nil;        ///< A snapshot of the row user is moving.
    static NSIndexPath  *sourceIndexPath = nil; ///< Initial index path, where gesture begins.
    
    switch (state) {
        case UIGestureRecognizerStateBegan: {
            if (indexPath) {
                _superOriginalIndex = [self.tableView indexPathForRowAtPoint:location];
 
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
            Item *previousItem = nil;
            Item *followingItem  = nil;
            
            if(_superOriginalIndex.row < indexPath.row){
                if (indexPath.row == (numberOfObjects - 1)) {
                    Item *originalLastItem = [self.fetchedResultsController.fetchedObjects objectAtIndex:indexPath.row];
                    int newItemNewOrder = originalLastItem.order.intValue + 1048576;
                    reorderedItem.order =  [NSNumber numberWithInt:newItemNewOrder];
                    
                }else{
                    previousItem  = [self.fetchedResultsController.fetchedObjects objectAtIndex:indexPath.row];
                    followingItem  = [self.fetchedResultsController.fetchedObjects objectAtIndex:indexPath.row+1];
                    
                    int previousItemOrder = [previousItem.order intValue];
                    int followingItemOrder = [followingItem.order intValue];
                    int newOrder = (previousItemOrder + followingItemOrder)/2;
                    reorderedItem.order = [NSNumber numberWithInt:newOrder];
                }
                
            }else{
                if (indexPath.row == 0) {
                    Item *originalFirstItem = [self.fetchedResultsController.fetchedObjects objectAtIndex:indexPath.row];
                    int newItemNewOrder = originalFirstItem.order.intValue / 2;
                    reorderedItem.order =  [NSNumber numberWithInt:newItemNewOrder];
                }else{
                    previousItem  = [self.fetchedResultsController.fetchedObjects objectAtIndex:indexPath.row-1];
                    followingItem  = [self.fetchedResultsController.fetchedObjects objectAtIndex:indexPath.row];
                
                    int previousItemOrder = [previousItem.order intValue];
                    int followingItemOrder = [followingItem.order intValue];
                    int newOrder = (previousItemOrder + followingItemOrder)/2;
                    reorderedItem.order = [NSNumber numberWithInt:newOrder];
                }
            }
            
            NSString *itemIdCharacter = [reorderedItem.itemId substringToIndex:1];
            NSLog(@"first char = %@", itemIdCharacter);
            
            if ([itemIdCharacter isEqualToString:@"1"]) {
                //do nothing
            }else{
                NSMutableArray *newArrayOfItemsToUpdate = [[[NSUserDefaults standardUserDefaults] valueForKey:@"itemsToUpdate"]mutableCopy];
                [newArrayOfItemsToUpdate addObject:reorderedItem.itemId];
                [[NSUserDefaults standardUserDefaults] setObject:newArrayOfItemsToUpdate forKey:@"itemsToUpdate"];
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
                
                
            NSError *error = nil;
            if (![context save:&error]) {
                NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
                abort();
            }
            [DoozerSyncManager syncWithServer:self.managedObjectContext];
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
        itemToToggleComplete.order = orderForCompleted;
    }
    
    if([itemToToggleComplete.done intValue] == 0){
        itemToToggleComplete.done = [NSNumber numberWithBool:true];
    }else{
        itemToToggleComplete.done = [NSNumber numberWithBool:false];
    }
    
    
    NSString *itemIdCharacter = [itemToToggleComplete.itemId substringToIndex:1];
    NSLog(@"first char = %@", itemIdCharacter);
    
    if ([itemIdCharacter isEqualToString:@"1"]) {
        //do nothing
    }else{
        NSMutableArray *newArrayOfItemsToUpdate = [[[NSUserDefaults standardUserDefaults] valueForKey:@"itemsToUpdate"]mutableCopy];
        [newArrayOfItemsToUpdate addObject:itemToToggleComplete.itemId];
        [[NSUserDefaults standardUserDefaults] setObject:newArrayOfItemsToUpdate forKey:@"itemsToUpdate"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
            // Save the context.
    NSError *error = nil;
    if (![context save:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    [DoozerSyncManager syncWithServer:self.managedObjectContext];

    
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
 
#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"showItem"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        NSManagedObject *object = [[self fetchedResultsController] objectAtIndexPath:indexPath];
        
        ItemViewController *controller = (ItemViewController *)[[segue destinationViewController] topViewController];
        controller.managedObjectContext = self.managedObjectContext;
        [controller setDetailItem:object];
        [controller setDisplayListOfItem:self.displayList];
        
        controller.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
        controller.navigationItem.leftItemsSupplementBackButton = YES;
        
        UIBarButtonItem *newBackButton =
        [[UIBarButtonItem alloc] initWithTitle:@""
                                         style:UIBarButtonItemStylePlain
                                        target:nil
                                        action:nil];
        [[self navigationItem] setBackBarButtonItem:newBackButton];
    }
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [[self.fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][section];
    return [sectionInfo numberOfObjects];
     
    //return [[self findChildren] count];
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
    
        Item *itemToDelete = [self.fetchedResultsController objectAtIndexPath:indexPath];

        NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
        [context deleteObject:[self.fetchedResultsController objectAtIndexPath:indexPath]];
        
        NSMutableArray *itemsToAdd = [[[NSUserDefaults standardUserDefaults] valueForKey:@"itemsToAdd"]mutableCopy];
        NSMutableArray *newItemsToAdd = [[NSMutableArray alloc]init];
        int matchCount = 0;
        for(id eachElement in itemsToAdd){
            if ([itemToDelete.itemId isEqualToString:eachElement]){
                matchCount +=1;
            }else{
                [newItemsToAdd addObject:eachElement];
            }
        }
        [[NSUserDefaults standardUserDefaults] setObject:newItemsToAdd forKey:@"itemsToAdd"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        if (matchCount == 0){
        NSMutableArray *itemsToDelete = [[[NSUserDefaults standardUserDefaults] valueForKey:@"itemsToDelete"]mutableCopy];
        [itemsToDelete addObject:itemToDelete.itemId];
        [[NSUserDefaults standardUserDefaults] setObject:itemsToDelete forKey:@"itemsToDelete"];
        [[NSUserDefaults standardUserDefaults] synchronize];

        }
        
        
        // Save the context.
        NSError *error = nil;
        if (![context save:&error]) {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
        [DoozerSyncManager syncWithServer:self.managedObjectContext];
        
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

//Used in the re-ordering of items - captures a snapshot of the cell to move around
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

