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
#import "ColorHelper.h"
#import "AppDelegate.h"


@interface ListViewController ()


@end

@implementation ListViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    Item *listForTitle = self.displayList;
    
    [self addHeaderItems];
    
    self.view.backgroundColor = [ColorHelper getUIColorFromString:listForTitle.color :1];
    
    //self.navigationController.navigationBar.barStyle  = UIBarStyleBlackTranslucent;
    //self.navigationController.navigationBar.barTintColor = tempColor;
    
    self.navigationItem.title = listForTitle.title;
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc]
                                               initWithTarget:self action:@selector(longPressGestureRecognized:)];
    [self.tableView addGestureRecognizer:longPress];
    
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(swiperight:)];
    [self.tableView addGestureRecognizer:panGesture];
    panGesture.delegate = self;
    
}

-(void)swiperight:(UIPanGestureRecognizer*)panGesture;
{
    static CGPoint startPoint = { 0.f, 0.f };
    static UIView *snapshot = nil;        ///< A snapshot of the row user is swiping.
    CGPoint location = [panGesture locationInView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:location];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];

    
    switch (panGesture.state) {
        case UIGestureRecognizerStateBegan:{
            NSLog(@"pan began ---------------");
            startPoint = location;
            snapshot = [self customSnapshoForSwiping:cell];

            break;
        }
        case UIGestureRecognizerStateChanged:{
            CGPoint location = [panGesture locationInView:self.view];
            
            if(location.x-startPoint.x > 10){
                // Take a snapshot of the selected row using helper method.
                
                // Add the snapshot as subview, centered at cell's center...
                //__block CGPoint center = cell.center;
                
                CGPoint offset = { (cell.center.x+(location.x-startPoint.x)), cell.center.y };
                NSLog(@"offset value = %f", offset.x);
                snapshot.center = offset;
                snapshot.alpha = 1.0;
                [self.tableView addSubview:snapshot];
                cell.hidden = YES;
                
            }
               
            break;
        }
        case UIGestureRecognizerStateEnded:{
            NSLog(@"pan ended ---------------");
            
            if (location.x-startPoint.x >= 50) {
                
                CGRect screenRect = [[UIScreen mainScreen] bounds];
                CGFloat screenWidth = screenRect.size.width;
                
                [UIView animateWithDuration:0.4
                                      delay:0.0
                                    options: UIViewAnimationOptionCurveLinear
                                 animations:^
                 {
                     CGRect frame = snapshot.frame;
                     frame.origin.x = (screenWidth);
                     snapshot.frame = frame;
                 }
                                 completion:^(BOOL finished)
                 {
                     NSLog(@"Completed");
                     Item *swipedItem = [self.fetchedResultsController objectAtIndexPath:indexPath];
                     [self cleanUpSwipedItem:swipedItem];
                     
                 }];

            }else if(location.x-startPoint.x > 10 && location.x-startPoint.x < 50){
                
                [UIView animateWithDuration:0.2
                                      delay:0.0
                                    options: UIViewAnimationOptionCurveEaseOut
                                 animations:^
                 {
                     CGRect frame = snapshot.frame;
                     frame.origin.x = (0);
                     snapshot.frame = frame;
                 }
                                 completion:^(BOOL finished)
                 {
                     NSLog(@"ReturniedCell");
                     [snapshot removeFromSuperview];
                     [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
                 }];
            }
            break;
        }
        default:
            break;
    }
}

-(void)cleanUpSwipedItem:(Item *)swipedItem{

    if (![swipedItem.type isEqualToString:@"completed_header"]) {
        NSLog(@"item title to toggle = %@", swipedItem.title);
        
        NSArray *listArray = [self.fetchedResultsController fetchedObjects];
        NSMutableArray *completedItemOrderValues = [[NSMutableArray alloc] init];
        NSMutableArray *allItemOrderValues = [[NSMutableArray alloc] init];
        
        int unCompletedCount = 0;
        
        for (id eachElement in listArray){
            Item *theItem = eachElement;
            [allItemOrderValues addObject:theItem.order];
            if ([theItem.done intValue] == 1) {
                [completedItemOrderValues addObject:theItem.order];
            }else{
                unCompletedCount += 1;
            }
        }
        
        int completedMinOrder = [[completedItemOrderValues valueForKeyPath:@"@min.intValue"] intValue];
        int maxItemOrder = [[allItemOrderValues valueForKeyPath:@"@max.intValue"] intValue];
        
        
        
        NSNumber *num = [NSNumber numberWithInt:completedMinOrder];
        
        int indexOfFirstCompleted = 0;
        
        if ([num intValue] == 0) {
            int newOrderForCompletedItem = maxItemOrder + 10000000;
            NSNumber *orderForCompleted = [NSNumber numberWithInt:newOrderForCompletedItem];
            swipedItem.order = orderForCompleted;
            
            if([swipedItem.done intValue] == 0){
                swipedItem.done = [NSNumber numberWithBool:true];
            }else{
                swipedItem.done = [NSNumber numberWithBool:false];
            }
            
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
            
            int indexOfCompletedHeader = indexOfFirstCompleted - 1;
            int indexOfLastUncompleted = indexOfFirstCompleted - 2;
            int newOrderForCompletedItem = 0;
            
            NSNumber *monkey = [allItemOrderValues objectAtIndex:indexOfCompletedHeader];
            int orderValOfCompletedHeader = [monkey intValue];
            
            if([swipedItem.done intValue] == 0){
                swipedItem.done = [NSNumber numberWithBool:true];
                newOrderForCompletedItem = ((completedMinOrder - orderValOfCompletedHeader)/2)+orderValOfCompletedHeader;
            }else{
                swipedItem.done = [NSNumber numberWithBool:false];
                
                
                int lastUncompletedOrder = 0;
                if (unCompletedCount > 1){
                    lastUncompletedOrder = [[allItemOrderValues objectAtIndex:indexOfLastUncompleted] intValue];
                }
                newOrderForCompletedItem = ((orderValOfCompletedHeader-lastUncompletedOrder)/2)+lastUncompletedOrder;
            }
            
            swipedItem.order = [NSNumber numberWithInt:newOrderForCompletedItem];
        }
        
        NSString *itemIdCharacter = [swipedItem.itemId substringToIndex:1];
        
        if ([itemIdCharacter isEqualToString:@"1"]) {
            //do nothing
        }else{
            NSMutableArray *newArrayOfItemsToUpdate = [[[NSUserDefaults standardUserDefaults] valueForKey:@"itemsToUpdate"]mutableCopy];
            [newArrayOfItemsToUpdate addObject:swipedItem.itemId];
            [[NSUserDefaults standardUserDefaults] setObject:newArrayOfItemsToUpdate forKey:@"itemsToUpdate"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
        // Save the context.
        
        AppDelegate* appDelegate = [AppDelegate sharedAppDelegate];
        NSManagedObjectContext* context = appDelegate.managedObjectContext;
        NSError *error = nil;
        if (![context save:&error]) {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
        [DoozerSyncManager syncWithServer:self.managedObjectContext];
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIPanGestureRecognizer *)otherGestureRecognizer {
    //This allows the custom PanGesture to be simultaneiously monitoring with the built-in swipe left to reveal delete button
    return YES;
}


- (void)addHeaderItems{
    Item *displayedList = self.displayList;
    NSLog(@"displayed list is = %@", displayedList.title);
    NSArray *itemsOnList = self.fetchedResultsController.fetchedObjects;
    int headerCount = 0;
    for (Item *eachItem in itemsOnList) {
        if ([eachItem.type isEqualToString:@"completed_header"]){
            headerCount += 1;
        }
    }
    if (headerCount == 0) {
        NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
        NSEntityDescription *entity = [[self.fetchedResultsController fetchRequest] entity];
        
        int completedCount = 0;
        for (Item *eachItem in itemsOnList) {
            if (eachItem.done.intValue == 1) {
                completedCount += 1;
            }
        }
        
        int orderValue = 0;
        
        if (completedCount == 0){
            if ([itemsOnList count] == 0) {
                NSLog(@"case 1");
                orderValue = 134217728;
            }else{
                NSLog(@"case 2");
                
                Item *lastItem = [itemsOnList objectAtIndex:([itemsOnList count] - 1)];
                orderValue = lastItem.order.intValue + 65536;
            }
        }else{
            int indexOfFirstCompleted = (int)[itemsOnList count] - completedCount;
            if (indexOfFirstCompleted == 0) {
                NSLog(@"case 3");
                
                Item *firstItem = [itemsOnList objectAtIndex:0];
                orderValue = firstItem.order.intValue / 2;
            }else{
                NSLog(@"case 4");
                
                Item *firstCompleted = [itemsOnList objectAtIndex:indexOfFirstCompleted];
                Item *lastUnCompleted = [itemsOnList objectAtIndex:(indexOfFirstCompleted-1)];
                orderValue = ((firstCompleted.order.intValue - lastUnCompleted.order.intValue) / 2) + lastUnCompleted.order.intValue;
            }
        }
        
        Item *newItem = [[Item alloc]initWithEntity:entity insertIntoManagedObjectContext:self.managedObjectContext];
        newItem.title = @"COMPLETED";
        newItem.type = @"completed_header";
        newItem.order = [NSNumber numberWithInt:orderValue];
        
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

    }else{
        NSLog(@"header found and equal to = %d", headerCount);
    }
    
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
    
    CGPoint location = [longPress locationInView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:location];
    
    Item *clickedItem = [self.fetchedResultsController objectAtIndexPath:indexPath];
    NSLog(@"clicked item title is %@, and header type is %@", clickedItem.title, clickedItem.type);

        UIGestureRecognizerState state = longPress.state;
    
        static UIView       *snapshot = nil;        ///< A snapshot of the row user is moving.
        static NSIndexPath  *sourceIndexPath = nil; ///< Initial index path, where gesture begins.
    
        switch (state) {
            case UIGestureRecognizerStateBegan: {
                
                if (indexPath) {
                    
                    if ([clickedItem.type isEqualToString:@"completed_header"]) {
                        self.allowDragging = NO;
                    }else{
                        self.allowDragging = YES;
                        
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


                }
                break;
            }
                
            case UIGestureRecognizerStateChanged: {
                if (self.allowDragging) {
                        
                    CGPoint center = snapshot.center;
                    center.y = location.y;
                    snapshot.center = center;
                    
                    // Is destination valid and is it different from source?
                    if (indexPath && ![indexPath isEqual:sourceIndexPath]) {
                        
                        NSLog(@"moving cells ----------------");
                        // ... move the rows.
                        [self.tableView moveRowAtIndexPath:sourceIndexPath toIndexPath:indexPath];
                        
                        // ... and update source so it is in sync with UI changes.
                        sourceIndexPath = indexPath;
                    }
                    
                NSLog(@"sourceIndexPath row = %ld and indexPath row = %ld", (long)sourceIndexPath.row, (long)indexPath.row);

                break;
                }
            }
                
            case UIGestureRecognizerStateEnded: {
                
                if (self.allowDragging) {
                    Item *reorderedItem = [self.fetchedResultsController.fetchedObjects objectAtIndex:_superOriginalIndex.row];
                    NSArray *itemsInTable = self.fetchedResultsController.fetchedObjects;
                    int headerOrderValue = 0;
                    for (Item *currentItem in itemsInTable){
                        if ([currentItem.type isEqualToString:@"completed_header"]) {
                            headerOrderValue = currentItem.order.intValue;
                        }
                    }
                    
                    NSLog(@"completed order value is %d", headerOrderValue);
                    
                    NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
                    
                    NSUInteger numberOfObjects = [self.fetchedResultsController.fetchedObjects count];
                    Item *previousItem = nil;
                    Item *followingItem  = nil;
                    
                    if(_superOriginalIndex.row < sourceIndexPath.row){
                        if (sourceIndexPath.row == (numberOfObjects - 1)) {
                            Item *originalLastItem = [self.fetchedResultsController.fetchedObjects objectAtIndex:sourceIndexPath.row];
                            int newItemNewOrder = originalLastItem.order.intValue + 1048576;
                            reorderedItem.order =  [NSNumber numberWithInt:newItemNewOrder];
                            
                        }else{
                            previousItem  = [self.fetchedResultsController.fetchedObjects objectAtIndex:sourceIndexPath.row];
                            followingItem  = [self.fetchedResultsController.fetchedObjects objectAtIndex:sourceIndexPath.row+1];
                            
                            int previousItemOrder = [previousItem.order intValue];
                            int followingItemOrder = [followingItem.order intValue];
                            int newOrder = (previousItemOrder + followingItemOrder)/2;
                            reorderedItem.order = [NSNumber numberWithInt:newOrder];
                        }
                        
                    }else{
                        if (sourceIndexPath.row == 0) {
                            Item *originalFirstItem = [self.fetchedResultsController.fetchedObjects objectAtIndex:sourceIndexPath.row];
                            int newItemNewOrder = originalFirstItem.order.intValue / 2;
                            reorderedItem.order =  [NSNumber numberWithInt:newItemNewOrder];
                        }else{
                            previousItem  = [self.fetchedResultsController.fetchedObjects objectAtIndex:sourceIndexPath.row-1];
                            followingItem  = [self.fetchedResultsController.fetchedObjects objectAtIndex:sourceIndexPath.row];
                            
                            int previousItemOrder = [previousItem.order intValue];
                            int followingItemOrder = [followingItem.order intValue];
                            int newOrder = (previousItemOrder + followingItemOrder)/2;
                            reorderedItem.order = [NSNumber numberWithInt:newOrder];
                        }
                    }
                    
                    NSLog(@"reordered item order is %@ and header orer is %d", reorderedItem.order, headerOrderValue);
                    
                    if (reorderedItem.order.intValue > headerOrderValue) {
                        reorderedItem.done = [NSNumber numberWithInt:1];
                    }else{
                        reorderedItem.done = [NSNumber numberWithInt:0];
                    }
                    
                    NSString *itemIdCharacter = [reorderedItem.itemId substringToIndex:1];
                    //NSLog(@"first char = %@", itemIdCharacter);
                    
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
    }

/*
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
        
        if([itemToToggleComplete.done intValue] == 0){
            itemToToggleComplete.done = [NSNumber numberWithBool:true];
        }else{
            itemToToggleComplete.done = [NSNumber numberWithBool:false];
        }
        
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
        
        int indexOfCompletedHeader = indexOfFirstCompleted - 1;
        int indexOfLastUncompleted = indexOfFirstCompleted - 2;
        int newOrderForCompletedItem = 0;
        
        NSNumber *monkey = [allItemOrderValues objectAtIndex:indexOfCompletedHeader];
        int orderValOfCompletedHeader = [monkey intValue];

        if([itemToToggleComplete.done intValue] == 0){
            itemToToggleComplete.done = [NSNumber numberWithBool:true];
            newOrderForCompletedItem = ((completedMinOrder - orderValOfCompletedHeader)/2)+orderValOfCompletedHeader;
        }else{
            itemToToggleComplete.done = [NSNumber numberWithBool:false];
            int lastUncompletedOrder = [[allItemOrderValues objectAtIndex:indexOfLastUncompleted] intValue];
            newOrderForCompletedItem = ((orderValOfCompletedHeader-lastUncompletedOrder)/2)+lastUncompletedOrder;

        }
        
        itemToToggleComplete.order = [NSNumber numberWithInt:newOrderForCompletedItem];
    }
    

    
    
    NSString *itemIdCharacter = [itemToToggleComplete.itemId substringToIndex:1];
    //NSLog(@"first char = %@", itemIdCharacter);
    
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
    //[self.tableView reloadData];
    [DoozerSyncManager syncWithServer:self.managedObjectContext];

    
}
*/

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
/*
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView == self.tableView) {
 
        if (scrollView.contentOffset.y < 0) {
            scrollView.contentOffset = CGPointZero;
        }
 
        
        NSLog(@"scroll happens");
    }
}
*/


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

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    Item *clickedItem = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    if ([clickedItem.type isEqualToString:@"completed_header"]) {
        
        if (self.showCompleted) {
            self.showCompleted = NO;
        }else{
            self.showCompleted = YES;
        }
        
        [self.tableView reloadData];
        
    }else{
        [self performSegueWithIdentifier:@"showItem" sender:self];
    }
    
}


- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {

    Item *object = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    NSNumber *done = object.done;
    if ([object.type isEqualToString:@"completed_header"]) {
        
        NSArray *itemsOnList = self.fetchedResultsController.fetchedObjects;
        
        int doneCount = 0;
        for (Item* eachItem in itemsOnList) {
            if (eachItem.done.intValue == 1) {
                doneCount +=1;
            }
        }
        
        
        Item *listForTitle = self.displayList;
        if (self.showCompleted) {
            cell.textLabel.text = [NSString stringWithFormat:@"\U000025BC\U0000FE0E %@ (%d)", object.title, doneCount];
        }else{
            cell.textLabel.text = [NSString stringWithFormat:@"\U000025B6\U0000FE0E %@ (%d)", object.title, doneCount];
        }
        
        cell.backgroundColor = [ColorHelper getUIColorFromString:listForTitle.color :1];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.textColor = [UIColor whiteColor];
        cell.textLabel.font = [UIFont systemFontOfSize:16];
        cell.textLabel.textAlignment = NSTextAlignmentLeft;
    }else{
        if ([done intValue] == 1) {
            NSString *titleText = object.title;
            
            NSDictionary* attributes = @{
                                         NSStrikethroughStyleAttributeName: [NSNumber numberWithInt:NSUnderlineStyleSingle]
                                         };
            
            NSAttributedString* attrText = [[NSAttributedString alloc] initWithString:titleText attributes:attributes];
            cell.textLabel.attributedText = attrText;
            
            cell.textLabel.textColor = [UIColor whiteColor];
            cell.textLabel.font = [UIFont systemFontOfSize:16];
            cell.textLabel.textAlignment = NSTextAlignmentLeft;
            cell.backgroundColor = [UIColor colorWithRed:255 green:255 blue:255 alpha:0.25];

            if (self.showCompleted) {
                cell.hidden = NO;
            }else{
                cell.hidden = YES;
            }
        }else{
            cell.textLabel.text = object.title;
            cell.textLabel.textColor = [UIColor blackColor];
            cell.textLabel.font = [UIFont systemFontOfSize:16];
            cell.textLabel.textAlignment = NSTextAlignmentLeft;
            cell.backgroundColor = [UIColor whiteColor];

        }
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}


- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
    
        Item *itemToDelete = [self.fetchedResultsController objectAtIndexPath:indexPath];
        
        NSLog(@"index path to delete = %@", indexPath);
        NSLog(@"item title to delete = %@", itemToDelete.title);


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
            NSLog(@"ChangeDelete index path to delete = %@", indexPath);
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

- (UIView *)customSnapshoForSwiping:(UIView *)inputView {
    
    // Make an image from the input view.
    UIGraphicsBeginImageContextWithOptions(inputView.bounds.size, NO, 0);
    [inputView.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    // Create an image view.
    UIView *snapshot = [[UIImageView alloc] initWithImage:image];
    snapshot.layer.masksToBounds = NO;
    snapshot.layer.cornerRadius = 0.0;
    //snapshot.layer.shadowOffset = CGSizeMake(-5.0, 0.0);
    //snapshot.layer.shadowRadius = 5.0;
    //snapshot.layer.shadowOpacity = 0.4;
    
    return snapshot;
}


@end

