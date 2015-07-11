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
#import "ListCustomCell.h"
#import "AddItemsToServer.h"
#import "CoreDataItemManager.h"

@interface ListViewController () <UITextFieldDelegate>
@end

@implementation ListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    Item *listForTitle = self.displayList;
    
    [self addHeaderItems];
    
    UIColor *tempColor = [ColorHelper getUIColorFromString:listForTitle.color :1];
    self.view.backgroundColor = tempColor;
    
    //self.navigationController.navigationBar.barStyle  = UIBarStyleBlackTranslucent;
    //self.navigationController.navigationBar.barTintColor = tempColor;
    
    //self.navigationItem.title = [NSString stringWithFormat:@"%@ - %@", listForTitle.title, listForTitle.itemId];
    self.navigationItem.title = listForTitle.title;
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc]
                                               initWithTarget:self action:@selector(longPressGestureRecognized:)];
    [self.tableView addGestureRecognizer:longPress];
    
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(swiperight:)];
    [self.tableView addGestureRecognizer:panGesture];
    
    panGesture.delegate = self;
    
    //self.navigationController.hidesBarsOnSwipe = YES;

    self.isScrolling = NO;
    self.longPressActive = NO;
    self.isRightSwiping = NO;
    self.rowOfNewItem = -1;
    
}

-(void)viewWillDisappear:(BOOL)animated{
    
    if (self.rowOfNewItem != -1) {
        NSIndexPath *pathOfNewItem = [NSIndexPath indexPathForRow:self.rowOfNewItem inSection:0];
        ListCustomCell *cell = (ListCustomCell *)[self.tableView cellForRowAtIndexPath:pathOfNewItem];
        Item *itemToSave = [self.fetchedResultsController objectAtIndexPath:pathOfNewItem];
        
        itemToSave.title = cell.cellItemTitle.text;
        NSLog(@"title to save = %@", itemToSave.title);
        
        [AddItemsToServer addThisItem:itemToSave];
        
        self.rowOfNewItem = -1;
        [self.tableView reloadData];
    }
    
}

-(void)scrollViewDidScroll:(UIScrollView *)sender {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    //ensure that the end of scroll is fired.
    [self performSelector:@selector(scrollViewDidEndScrollingAnimation:) withObject:nil afterDelay:0.3];
    
    self.isScrolling = YES;
}

-(void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    self.isScrolling = NO;
}

-(void)swiperight:(UIPanGestureRecognizer*)panGesture; {

    static CGPoint startPoint = { 0.f, 0.f };
    static UIView *snapshot = nil;        ///< A snapshot of the row user is swiping.
    CGPoint location = [panGesture locationInView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:location];
    NSIndexPath *originalIndexPath = [self.tableView indexPathForRowAtPoint:startPoint];
    ListCustomCell *cell = (ListCustomCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    ListCustomCell *originalCell = (ListCustomCell *)[self.tableView cellForRowAtIndexPath:originalIndexPath];
    Item *swipedItem = [self.fetchedResultsController objectAtIndexPath:originalIndexPath];
    
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenRect.size.width;
    BOOL swipeOnHiddenItem = NO;

    if (!self.showCompleted && (swipedItem.done.intValue == 1)) {
        //NSLog(@"don't allow swiping!");
        swipeOnHiddenItem = YES;
    }
    
    if ((!self.longPressActive && !self.isScrolling && !swipeOnHiddenItem) || self.isRightSwiping) {
        
        switch (panGesture.state) {
            case UIGestureRecognizerStateBegan:{
                //NSLog(@"pan began ---------------");
                startPoint = location;
                snapshot = [self customSnapshoForSwiping:cell];


                break;
            }
            case UIGestureRecognizerStateChanged:{
                CGPoint location = [panGesture locationInView:self.view];
                
                if(location.x-startPoint.x > 10 && ![swipedItem.type isEqualToString:@"completed_header"]){
                    
                    self.isRightSwiping = YES;
                    
                    // Add the snapshot as subview, centered at cell's center...
                    
                    CGPoint offset = { ((location.x-startPoint.x) + screenWidth/2), originalCell.center.y };

                    snapshot.center = offset;
                    snapshot.alpha = 1.0;
                    [self.tableView addSubview:snapshot];
                    originalCell.hidden = NO;
                    Item *parent = self.displayList;
                    originalCell.backgroundColor = [ColorHelper getUIColorFromString:parent.color :1];
                    originalCell.cellItemTitle.attributedText = nil;
                    originalCell.cellItemTitle.text = @"\U00002714\U0000FE0E";
                    
                    if (swipedItem.done.intValue == 1) {
                        if ((location.x-startPoint.x) > screenWidth/3) {
                            originalCell.cellItemTitle.textColor = [UIColor lightGrayColor];
                        }else{
                            originalCell.cellItemTitle.textColor = [UIColor whiteColor];
                        }
                    }else{
                        if ((location.x-startPoint.x) > screenWidth/3) {
                            originalCell.cellItemTitle.textColor = [UIColor whiteColor];

                        }else{
                            originalCell.cellItemTitle.textColor = [UIColor lightGrayColor];
                        }
                    }
                    originalCell.cellItemTitle.font = [UIFont boldSystemFontOfSize:26];
                    
                }
                   
                break;
            }
            case UIGestureRecognizerStateEnded:{
                //NSLog(@"pan ended ---------------");
                
                if (location.x-startPoint.x >= screenWidth/3 && ![swipedItem.type isEqualToString:@"completed_header"]) {
                    
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
                         [self cleanUpSwipedItem:swipedItem];
                         [snapshot removeFromSuperview];
                         
                         NSArray *itemsOnList = self.fetchedResultsController.fetchedObjects;
                         for (Item *eachItem in itemsOnList) {
                             if ([eachItem.type isEqualToString:@"completed_header"]) {
                
                                 //set the notes field to a blank string, so that CoreData updates the header
                                 //for completed items and prompts a reload of completed items count
                                 eachItem.notes = @" ";
                             }
                         }
                         self.isRightSwiping = NO;

                     }];

                }else if(location.x-startPoint.x >= 0 && location.x-startPoint.x < screenWidth/3 && ![swipedItem.type isEqualToString:@"completed_header"]){
                    
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
                         swipedItem.notes = @" ";
                         self.isRightSwiping = NO;

                    }];
               
                }
                
                else{
                    NSLog(@"Catch all case for ENDED");
                    [snapshot removeFromSuperview];
                    originalCell.hidden = NO;
                    swipedItem.notes = @" ";
                    self.isRightSwiping = NO;

                }
                
                break;
                
            }
            default:{
                [snapshot removeFromSuperview];
                self.isRightSwiping = NO;

            }
                
                break;
        }
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
        
        NSLog(@"checking for rebalancing!!!!!!");
        [self rebalanceListIfNeeded];
        
        [DoozerSyncManager syncWithServer];
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIPanGestureRecognizer *)otherGestureRecognizer {
    //This allows the custom PanGesture to be simultaneiously monitoring with the built-in swipe left to reveal delete button
    return YES;
}

-(void)rebalanceListIfNeeded{
    NSLog(@"inside rebalance list if needed method");
    
    NSArray *itemsOnList = self.fetchedResultsController.fetchedObjects;
    BOOL rebalanceNeeded = NO;
    int previousItemOrder = 0;
    for (Item *eachItem in itemsOnList){
        int diff = eachItem.order.intValue - previousItemOrder;
        previousItemOrder = eachItem.order.intValue;
        NSLog(@"diff ===== %d", diff);
        if (diff < 2){
            rebalanceNeeded = YES;
        }
    }
    if (rebalanceNeeded) {
        [CoreDataItemManager rebalanceItemOrderValues:itemsOnList];
    }
    
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
        
        [DoozerSyncManager syncWithServer];

    }else{
        NSLog(@"header found and equal to = %d", headerCount);
    }
    
}

- (IBAction)addItemButton:(id)sender {
    
    if (self.rowOfNewItem != -1) {
        NSIndexPath *pathOfNewItem = [NSIndexPath indexPathForRow:self.rowOfNewItem inSection:0];
        ListCustomCell *cell = (ListCustomCell *)[self.tableView cellForRowAtIndexPath:pathOfNewItem];
        Item *itemToSave = [self.fetchedResultsController objectAtIndexPath:pathOfNewItem];
        
        itemToSave.title = cell.cellItemTitle.text;
        NSLog(@"title to save = %@", itemToSave.title);
        
        [AddItemsToServer addThisItem:itemToSave];
        
        self.rowOfNewItem = -1;
        [self.tableView reloadData];
    }
    
    NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
    NSEntityDescription *entity = [[self.fetchedResultsController fetchRequest] entity];
    
    Item *newItem = [[Item alloc]initWithEntity:entity insertIntoManagedObjectContext:self.managedObjectContext];
    NSArray *itemArray = [self.fetchedResultsController fetchedObjects];
    long numberOfResults = [itemArray count];
    
    NSArray *visibleRows = [self.tableView indexPathsForVisibleRows];
    NSIndexPath *topRowPath = [visibleRows objectAtIndex:0];
    Item *topItem = [self.fetchedResultsController objectAtIndexPath:topRowPath];
    
    if (numberOfResults == 0) {
        newItem.order = [NSNumber numberWithLong:16777216];
        NSLog(@"Zero items in list - setting order value to 16777216");
    } else if (topRowPath.row == 0){
        newItem.order = [NSNumber numberWithInt:topItem.order.intValue/2];
        NSLog(@"top row is 0, cutting it's order value in half");
    }
    else{
        Item *secondItem = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:topRowPath.row+1 inSection:0]];
        int newOrderValue = (secondItem.order.intValue - topItem.order.intValue)/2 + topItem.order.intValue;
        newItem.order = [NSNumber numberWithInt:newOrderValue];
       // newItemIndexPath = [NSIndexPath indexPathForRow:topRowPath. inSection:<#(NSInteger)#>]
        
        NSLog(@"top item order = %@, second item order = %@, newItem order = %@", topItem.order, secondItem.order, newItem.order);
        
    }
        
    newItem.done = 0;
    newItem.notes = @" ";
    
    Item *parentList = self.displayList;
    
    newItem.parent = parentList.itemId;
    
    double timestamp = [[NSDate date] timeIntervalSince1970];
    newItem.itemId = [NSString stringWithFormat:@"%f", timestamp];
    
    // Save the context.
    NSError *error = nil;
    if (![context save:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    NSIndexPath *newItemIndexPath = [[NSIndexPath alloc] init];

    if (topRowPath.row == 0){
    newItemIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    }
    else{
    newItemIndexPath = [NSIndexPath indexPathForRow:topRowPath.row+1 inSection:0];
    }
    
    ListCustomCell *cell = (ListCustomCell *)[self.tableView cellForRowAtIndexPath:newItemIndexPath];
    self.rowOfNewItem = (int)newItemIndexPath.row;
    cell.cellItemTitle.enabled = YES;
    cell.cellItemTitle.delegate = self;
    
    for (int i = 0; i <= (int)numberOfResults; i++) {

        if (i != self.rowOfNewItem) {
            NSIndexPath *pathToLoad = [NSIndexPath indexPathForRow:i inSection:0];
            Item *itemToReload = [self.fetchedResultsController objectAtIndexPath:pathToLoad];
            itemToReload.forceUpdateString = @" ";
            //NSLog(@"row to load = %d", i);
        }
    }
    
    [cell.cellItemTitle becomeFirstResponder];

}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    NSLog(@"text field is beginning editting");
    //[textField performSelector:@selector(selectAll:) withObject:nil afterDelay:0.0];
    
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    // It is important for you to hide the keyboard

    NSLog(@"text field should end editing");
     NSString *currentText = textField.text;
     
     Item *itemInCell = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:self.rowOfNewItem inSection:0]];
     
     itemInCell.title = currentText;
    
     // Force any text fields that might be being edited to end
     [self.view.window endEditing: YES];
    
     NSMutableArray *newArrayOfItemsToAdd = [[[NSUserDefaults standardUserDefaults] valueForKey:@"itemsToAdd"]mutableCopy];
     [newArrayOfItemsToAdd addObject:itemInCell.itemId];
     [[NSUserDefaults standardUserDefaults] setObject:newArrayOfItemsToAdd forKey:@"itemsToAdd"];
     [[NSUserDefaults standardUserDefaults] synchronize];
     
     [textField resignFirstResponder];
     
     //[self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
    
    
    NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
    
    // Save the context.
    NSError *error = nil;
    if (![context save:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    self.rowOfNewItem = -1;
    [self.tableView reloadData];
    
    [self rebalanceListIfNeeded];
    
    [DoozerSyncManager syncWithServer];
    
    return YES;
}
 
- (IBAction)longPressGestureRecognized:(id)sender {
    
    UILongPressGestureRecognizer *longPress = (UILongPressGestureRecognizer *)sender;
    
    CGPoint location = [longPress locationInView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:location];
    
    Item *clickedItem = [self.fetchedResultsController objectAtIndexPath:indexPath];
    //NSLog(@"clicked item title is %@, and header type is %@", clickedItem.title, clickedItem.type);

        UIGestureRecognizerState state = longPress.state;
    
        static UIView       *snapshot = nil;        ///< A snapshot of the row user is moving.
        static NSIndexPath  *sourceIndexPath = nil; ///< Initial index path, where gesture begins.
    
        ListCustomCell *cell = (ListCustomCell *)[self.tableView cellForRowAtIndexPath:indexPath];

        switch (state) {
            case UIGestureRecognizerStateBegan: {
                
                self.longPressActive = YES;
                
                if (indexPath) {
                    
                    if ([clickedItem.type isEqualToString:@"completed_header"]) {
                        self.allowDragging = NO;
                    }else{
                        self.allowDragging = YES;
                        
                        _superOriginalIndex = [self.tableView indexPathForRowAtPoint:location];
                        
                        sourceIndexPath = indexPath;
                        
                        
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
                        
                        Item *itemBeingPassed = [self.fetchedResultsController objectAtIndexPath:indexPath];
                        int totalRows = (int)[self.fetchedResultsController.fetchedObjects count];
                        
                        
                        if ((clickedItem.done.intValue == 0) && [itemBeingPassed.type isEqualToString:@"completed_header"]) {
                            NSLog(@"passing the completed header");
                            self.showCompleted = YES;
                            int currentRow = (int)indexPath.row+1;
                            
                            NSMutableArray *indexPaths = [[NSMutableArray alloc]init];
                            for(int r = currentRow; r<totalRows; r++){
                                [indexPaths addObject:[NSIndexPath indexPathForRow:r inSection:0]];
                                
                                ListCustomCell *cell = (ListCustomCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:r inSection:0] ];
                                cell.hidden = NO;
                            }
                        }
                        // ... and update source so it is in sync with UI changes.
                        sourceIndexPath = indexPath;
                    }
                    
                //NSLog(@"sourceIndexPath row = %ld and indexPath row = %ld", (long)sourceIndexPath.row, (long)indexPath.row);

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
                    
                    //NSLog(@"completed order value is %d", headerOrderValue);
                    
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
                    
                    //NSLog(@"reordered item order is %@ and header orer is %d", reorderedItem.order, headerOrderValue);
                    
                    //dropping an uncompleted item into the 'completed' zone. Set the item's 'done' value appropriately.
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
                    
                    
                    //TODO figure out why the cell sometimes doesn't show!!!!!!!!!!
                    //cell.hidden = NO;
                    
                    [self rebalanceListIfNeeded];

                    [DoozerSyncManager syncWithServer];
                    [self.tableView reloadData];

                }
                
            default: {
                // Clean up.
                self.longPressActive = NO;
                //NSLog(@"In clean up of Long Press method");
                ListCustomCell *cell = (ListCustomCell *)[self.tableView cellForRowAtIndexPath:sourceIndexPath];
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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    return 50;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    //NSLog(@"cell for row at index pathing at row %ld", (long)indexPath.row);
    
    ListCustomCell *cell = [tableView dequeueReusableCellWithIdentifier:@"itemCell" forIndexPath:indexPath];

    [self configureCell:cell atIndexPath:indexPath];
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    Item *clickedItem = [self.fetchedResultsController objectAtIndexPath:indexPath];

    if (self.rowOfNewItem != -1) {
        NSIndexPath *pathOfNewItem = [NSIndexPath indexPathForRow:self.rowOfNewItem inSection:0];
        ListCustomCell *cell = (ListCustomCell *)[self.tableView cellForRowAtIndexPath:pathOfNewItem];
        Item *itemToSave = [self.fetchedResultsController objectAtIndexPath:pathOfNewItem];
        
        itemToSave.title = cell.cellItemTitle.text;
        NSLog(@"title to save = %@", itemToSave.title);
        [self rebalanceListIfNeeded];

        [AddItemsToServer addThisItem:itemToSave];
        
        self.rowOfNewItem = -1;
        [self.tableView reloadData];
    }else{
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
}

- (void)configureCell:(ListCustomCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    
    UIView *viewToRemove = nil;
    while((viewToRemove = [cell viewWithTag:5151]) != nil) {
        [viewToRemove removeFromSuperview];
    }
    
    Item *object = [self.fetchedResultsController objectAtIndexPath:indexPath];
    //NSLog(@"Configuring -------- Cell for item == %@", object.title);

    cell.cellItemTitle.enabled = NO;
    
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
        NSString *titleText = nil;
        if (self.showCompleted) {
            titleText = [NSString stringWithFormat:@"\U000025BC\U0000FE0E %@ (%d)", object.title, doneCount];
        }else{
            titleText = [NSString stringWithFormat:@"\U000025B6\U0000FE0E %@ (%d)", object.title, doneCount];
        }
        
        cell.cellItemTitle.attributedText = nil;
        cell.cellItemTitle.text = titleText;
        cell.backgroundColor = [ColorHelper getUIColorFromString:listForTitle.color :1];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.cellItemTitle.textColor = [UIColor whiteColor];
        cell.cellItemTitle.font = [UIFont systemFontOfSize:16];
        cell.cellItemTitle.textAlignment = NSTextAlignmentLeft;
        
    }else{
        if ([done intValue] == 1) {
            NSString *titleText = object.title;
            
            cell.cellItemTitle.text = titleText;
            cell.cellItemTitle.textColor = [UIColor colorWithRed:255 green:255 blue:255 alpha:0.5];
            cell.cellItemTitle.font = [UIFont systemFontOfSize:16];
            cell.cellItemTitle.textAlignment = NSTextAlignmentLeft;
            cell.backgroundColor = [UIColor colorWithRed:255 green:255 blue:255 alpha:0.25];

            if (self.showCompleted) {
                CGRect screenRect = [[UIScreen mainScreen] bounds];
                CGFloat screenWidth = screenRect.size.width;
                UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(15, 25, screenWidth-30, 1)];
                lineView.backgroundColor = [UIColor colorWithRed:255 green:255 blue:255 alpha:0.5];
                lineView.tag = 5151;
                [cell addSubview:lineView];

                cell.hidden = NO;

            }else{


                cell.hidden = YES;

            }
        }else{
            
            cell.cellItemTitle.attributedText = nil;
            cell.cellItemTitle.text = object.title;
            cell.cellItemTitle.textColor = [UIColor blackColor];
            cell.cellItemTitle.font = [UIFont systemFontOfSize:16];
            cell.cellItemTitle.textAlignment = NSTextAlignmentLeft;
            
            if (self.rowOfNewItem == -1) {
                cell.backgroundColor = [UIColor whiteColor];
                //NSLog(@"setting background color to white for row %ld", (long)indexPath.row);
            }else{
                if (self.rowOfNewItem == indexPath.row) {
                    cell.backgroundColor = [UIColor whiteColor];
                    //NSLog(@"setting background color to white for row %ld", (long)indexPath.row);

                }else{
                    cell.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.5];
                    //NSLog(@"setting background color to transparent for row %ld", (long)indexPath.row);
                }
            }
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
        [DoozerSyncManager syncWithServer];
        
    }
}

#pragma mark - Fetched results controller
- (NSFetchedResultsController *)fetchedResultsController {
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

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
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
      newIndexPath:(NSIndexPath *)newIndexPath {
    UITableView *tableView = self.tableView;
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            NSLog(@"ChangeInsert index path to delete = %@", indexPath);
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            NSLog(@"ChangeDelete index path to delete = %@", indexPath);
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
        
        case NSFetchedResultsChangeUpdate:
            //NSLog(@"ChangeUpdate index path to UPDATE = %@", indexPath);
            [self configureCell:(ListCustomCell *)[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            //[tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
            break;
         
            
        case NSFetchedResultsChangeMove:
            NSLog(@"moving rows in CHANGEMOVE");
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView endUpdates];
}

#pragma mark - Helper methods
- (UIView *)customSnapshoFromView:(UIView *)inputView {
    //Used in the re-ordering of items - captures a snapshot of the cell to move around
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

    return snapshot;
}

@end

