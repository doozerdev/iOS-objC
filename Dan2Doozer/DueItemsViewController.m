//
//  DueItemsViewController.m
//  Doozer
//
//  Created by Daniel Apone on 7/23/15.
//  Copyright © 2015 Daniel Apone. All rights reserved.
//

#import "DueItemsViewController.h"
#import "Item.h"
#import "AppDelegate.h"
#import "ColorHelper.h"
#import "ItemVC.h"
#import "DeleteItemFromServer.h"
#import "UpdateItemsOnServer.h"
#import "CoreDataItemManager.h"
#import "Intercom.h"

@interface DueItemsViewController () <UIGestureRecognizerDelegate>

@end

@implementation DueItemsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(swiperight:)];
    [self.view addGestureRecognizer:panGesture];
    panGesture.delegate =self;
    
    [self setNeedsStatusBarAppearanceUpdate];
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    //self.tableView.sectionHeaderHeight = 20.0;
    self.tableView.sectionFooterHeight = 0.0;
    self.tableView.backgroundColor = [UIColor lightGrayColor];
    self.view.backgroundColor = [UIColor lightGrayColor];
    
    self.isScrolling = NO;
    self.isRightSwiping = NO;
    
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleDefault;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    
    return YES;
}

-(void)scrollViewDidScroll:(UIScrollView *)sender {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    //ensure that the end of scroll is fired.
    [self performSelector:@selector(scrollViewDidEndScrollingAnimation:) withObject:nil afterDelay:0.3];
    
    self.isScrolling = YES;
}

-(void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    
    NSLog(@"ended scrolling");
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    self.isScrolling = NO;
}


- (void)viewWillAppear:(BOOL)animated{
    
    NSLog(@"in view will appear!!!!!!!!!!!!!!!!!!");
    self.navigationController.navigationBar.barStyle  = UIBarStyleDefault;
    self.navigationController.navigationBar.barTintColor = [UIColor whiteColor];
    self.navigationController.navigationBar.tintColor = [UIColor blackColor];

    self.tableView.backgroundColor = [UIColor blackColor];
    
    [self.navigationController.navigationBar setTitleTextAttributes: @{
                                                                       NSForegroundColorAttributeName: [UIColor blackColor],
                                                                       NSFontAttributeName: [UIFont fontWithName:@"Avenir" size:20],
                                                                       }];
    
    self.navigationItem.title = @"Due Tasks";
    [self calculateSections];
    UIView *backView = [[UIView alloc] init];
    
    if ([self.sectionsToShow count] == 0) {
        [backView setBackgroundColor:[UIColor whiteColor]];
    }else{
        
        Item *finalItem = [self.sectionsToShow objectAtIndex:[self.sectionsToShow count] - 1];
        [backView setBackgroundColor:[ColorHelper getUIColorFromString:finalItem.color :1]];
        //[backView setBackgroundColor:[UIColor whiteColor]];

    }
    
    [self.tableView setBackgroundView:backView];
    [self.tableView reloadData];
    
}


- (void)calculateSections{
    
    self.numberOfLists = 0;
    self.sectionsToShow = [[NSMutableArray alloc]init];
    NSDateFormatter *df = [[NSDateFormatter alloc]init];
    [df setDateFormat:@"yyyyMMdd"];
    NSString *currentDateString = [df stringFromDate:[NSDate date]];
    
    NSInteger numberOfTotalLists = [self.fetchedResultsController.fetchedObjects count];
    NSInteger numberOfListsWithDueItems = 0;
    
    for (int i = 0; i <+ numberOfTotalLists; i++) {
        
        Item *parent = [self.fetchedResultsController.fetchedObjects objectAtIndex:i];
        NSArray *children = [self getItemsOnList:parent.itemId];
        int count = 0;
        for (Item *eachItem in children){
            if (eachItem.done.intValue == 0) {
                NSString *dueDateString = [df stringFromDate:eachItem.duedate];
                if (dueDateString.intValue > 0 && dueDateString.intValue <= currentDateString.intValue) {
                    NSLog(@"due item is = %@", eachItem.title);
                    count += 1;
                }
            }
        }
        if (count > 0) {
            numberOfListsWithDueItems += 1;
            [self.sectionsToShow addObject:parent];
        }
    }
    self.numberOfLists = numberOfListsWithDueItems;
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)swiperight:(UIPanGestureRecognizer*)panGesture; {
    
    static CGPoint startPoint = { 0.f, 0.f };
    static UIView *snapshot = nil;        ///< A snapshot of the row user is swiping.
    CGPoint location = [panGesture locationInView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:location];
    NSIndexPath *originalIndexPath = [self.tableView indexPathForRowAtPoint:startPoint];
    
    if (indexPath) {
        
        UITableViewCell *cell = (UITableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
        UITableViewCell *originalCell = (UITableViewCell *)[self.tableView cellForRowAtIndexPath:originalIndexPath];
        Item *swipedItem = [self findItemAtIndexPath:originalIndexPath];
        
        CGRect screenRect = [[UIScreen mainScreen] bounds];
        CGFloat screenWidth = screenRect.size.width;
        BOOL swipeOnHiddenItem = NO;
        int swipeThreshold = 100;
        
        if (( !self.isScrolling && !swipeOnHiddenItem) || self.isRightSwiping) {
            
            switch (panGesture.state) {
                case UIGestureRecognizerStateBegan:{
                    //NSLog(@"pan began ---------------");
                    startPoint = location;
                    snapshot = [self customSnapshoForSwiping:cell];
                    
                    
                    break;
                }
                case UIGestureRecognizerStateChanged:{
                    CGPoint location = [panGesture locationInView:self.view];
                    
                    if(location.x-startPoint.x > 10){
                        
                        self.isRightSwiping = YES;
                        
                        // Add the snapshot as subview, centered at cell's center...
                        
                        CGPoint offset = { ((location.x-startPoint.x) + screenWidth/2), originalCell.center.y };
                        
                        snapshot.center = offset;
                        snapshot.alpha = 1.0;
                        [self.tableView addSubview:snapshot];
                        Item *parent = [self.sectionsToShow objectAtIndex:originalIndexPath.section];
                        originalCell.backgroundColor = [ColorHelper getUIColorFromString:parent.color :1];
                        originalCell.textLabel.text = @"\U00002713\U0000FE0E";
                        
                        if (swipedItem.done.intValue == 1) {
                            if ((location.x-startPoint.x) > swipeThreshold) {
                                originalCell.textLabel.textColor = [UIColor lightGrayColor];
                            }else{
                                originalCell.textLabel.textColor = [UIColor whiteColor];
                            }
                        }else{
                            if ((location.x-startPoint.x) > swipeThreshold) {
                                originalCell.textLabel.textColor = [UIColor whiteColor];
                                
                            }else{
                                originalCell.textLabel.textColor = [UIColor lightGrayColor];
                            }
                        }
                        originalCell.textLabel.font = [UIFont boldSystemFontOfSize:26];
                        
                    }
                    
                    break;
                }
                case UIGestureRecognizerStateEnded:{
                    //NSLog(@"pan ended ---------------");
                    
                    if (location.x-startPoint.x >= swipeThreshold) {
                        
                        NSLog(@"locationX is %f, startpointX is %f, and swipeThreshold is %d", location.x, startPoint.x, swipeThreshold);
                        
                        
                        float velocity = 1000; //pixels per second
                        
                        float animationDuration = (screenWidth - (location.x - startPoint.x))/velocity;
                        NSLog(@"animation duration = %f", animationDuration);
                        
                        [UIView animateWithDuration:animationDuration
                                              delay:0.0
                                            options: UIViewAnimationOptionCurveEaseInOut
                                         animations:^
                         {
                             CGRect frame = snapshot.frame;
                             frame.origin.x = (screenWidth);
                             snapshot.frame = frame;
                         }
                                         completion:^(BOOL finished)
                         {
                             NSLog(@"Completed for item == %@", swipedItem.title);
                             [self cleanUpSwipedItem:swipedItem];
                             [snapshot removeFromSuperview];
                             [self.tableView reloadData];
                             //[self.tableView deleteRowsAtIndexPaths:@[originalIndexPath] withRowAnimation:UITableViewRowAnimationNone];
                             //[self reloadSectionsIfNeeded:originalIndexPath];

                             self.isRightSwiping = NO;
                             
                         }];
                        
                    }else if(location.x-startPoint.x >= 0 && location.x-startPoint.x < swipeThreshold){
                        
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
                             [self.tableView reloadRowsAtIndexPaths:@[originalIndexPath] withRowAnimation:UITableViewRowAnimationNone];
                             self.isRightSwiping = NO;
                             
                         }];
                        
                    }
                    
                    else{
                        NSLog(@"Catch all case for ENDED");
                        [snapshot removeFromSuperview];
                        
                        if (self.isRightSwiping) {
                            [self.tableView reloadRowsAtIndexPaths:@[originalIndexPath] withRowAnimation:UITableViewRowAnimationNone];
                        }
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
}

-(void)cleanUpSwipedItem:(Item *)swipedItem{
    
        NSLog(@"item title to toggle = %@", swipedItem.title);
        
        NSArray *listArray = [self getItemsOnList:swipedItem.parent];
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
    
    [self rebalanceListIfNeeded:swipedItem.parent];
    
    [UpdateItemsOnServer updateThisItem:swipedItem];
    
    int timestamp = [[NSDate date] timeIntervalSince1970];
    NSString *date = [NSString stringWithFormat:@"%d", timestamp];
    [Intercom logEventWithName:@"Completed_Item_From_DueItems_Screen" metaData: @{@"date": date}];

    //[self.tableView reloadData];
    
}

-(void)rebalanceListIfNeeded:(NSString *)parentId{
    AppDelegate* appDelegate = [AppDelegate sharedAppDelegate];
    NSManagedObjectContext* context = appDelegate.managedObjectContext;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"ItemRecord" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    
    [fetchRequest setFetchBatchSize:20];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"parent == %@", parentId];
    [fetchRequest setPredicate:predicate];
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"order" ascending:YES];
    NSArray *sortDescriptors = @[sortDescriptor];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    NSFetchedResultsController *newFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:context sectionNameKeyPath:nil cacheName:@"ListTemp"];
    [NSFetchedResultsController deleteCacheWithName:@"ListTemp"];
    
    NSError *error = nil;
    if (![newFetchedResultsController performFetch:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    NSArray *itemsOnList = newFetchedResultsController.fetchedObjects;
    BOOL rebalanceNeeded = NO;
    int previousItemOrder = 0;
    for (Item *eachItem in itemsOnList){
        int diff = eachItem.order.intValue - previousItemOrder;
        previousItemOrder = eachItem.order.intValue;
        if (diff < 2){
            rebalanceNeeded = YES;
        }
    }
    if (rebalanceNeeded) {
        [CoreDataItemManager rebalanceItemOrderValues:itemsOnList];
    }
    
}



- (NSArray *)getItemsOnList :(NSString *)parentId{
    
    AppDelegate* appDelegate = [AppDelegate sharedAppDelegate];
    NSManagedObjectContext* context = appDelegate.managedObjectContext;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"ItemRecord" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    
    [fetchRequest setFetchBatchSize:20];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"parent == %@", parentId];
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
        
    NSArray *itemsOnSelectedList = aFetchedResultsController.fetchedObjects;
    return itemsOnSelectedList;
}

- (Item *)findItemAtIndexPath:(NSIndexPath *)indexPath{
    
    NSLog(@"indexpath clicked section = %ld, row = %ld", (long)indexPath.section, (long)indexPath.row);
    
    Item *list = [self.sectionsToShow objectAtIndex:indexPath.section];
    NSArray *itemsOnList = [self getItemsOnList:list.itemId];
    
    NSDateFormatter *df = [[NSDateFormatter alloc]init];
    [df setDateFormat:@"yyyyMMdd"];
    NSString *currentDateString = [df stringFromDate:[NSDate date]];
    
    NSMutableArray *dueItems = [[NSMutableArray alloc]init];
    for (Item *eachItem in itemsOnList){
        if (eachItem.done.intValue == 0) {
            NSString *dueDateString = [df stringFromDate:eachItem.duedate];
            if (dueDateString.intValue > 0 && dueDateString.intValue <= currentDateString.intValue) {
                [dueItems addObject:eachItem];
            }
        }
    }
    
    
    Item *itemInCell = [dueItems objectAtIndex:indexPath.row];
    return itemInCell;
    
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    //NSLog(@"count = %lu", [self.fetchedResultsController.fetchedObjects count]);
    //NSLog(@"num sections called");
    
    [self calculateSections];

    return self.numberOfLists;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    NSDateFormatter *df = [[NSDateFormatter alloc]init];
    [df setDateFormat:@"yyyyMMdd"];
    NSString *currentDateString = [df stringFromDate:[NSDate date]];
    
    Item *parent = [self.sectionsToShow objectAtIndex:section];
    NSArray *children = [self getItemsOnList:parent.itemId];
    int count = 0;
    for (Item *eachItem in children){
        if (eachItem.done.intValue == 0) {
            NSString *dueDateString = [df stringFromDate:eachItem.duedate];
            if (dueDateString.intValue > 0 && dueDateString.intValue <= currentDateString.intValue) {
                count += 1;
            }
        }
    }
    return count;

}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 60;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    return 60;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    Item *itemInHeader = [self.sectionsToShow objectAtIndex:section];

    UIView *tempView=[[UIView alloc]initWithFrame:CGRectMake(0,200,300,244)];
    tempView.backgroundColor=[ColorHelper getUIColorFromString:itemInHeader.color :1];
    
    UILabel *tempLabel=[[UILabel alloc]initWithFrame:CGRectMake(15,8,300,44)];
    tempLabel.backgroundColor=[UIColor clearColor];
    tempLabel.textColor = [UIColor whiteColor];
    tempLabel.font = [UIFont fontWithName:@"Avenir" size:17];
    tempLabel.text= itemInHeader.title;
    
    [tempView addSubview:tempLabel];
    
    return tempView;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"dueCells" forIndexPath:indexPath];
    
    // Configure the cell...
    NSInteger section = indexPath.section;
    
    Item *parentList = [self.sectionsToShow objectAtIndex:section];
    
    UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0, cell.contentView.frame.size.height - 3.0, cell.contentView.frame.size.width+100, 3)];
    
    lineView.backgroundColor = [ColorHelper getUIColorFromString:parentList.color :1];
    [cell.contentView addSubview:lineView];
    
    NSDateFormatter *df = [[NSDateFormatter alloc]init];
    [df setDateFormat:@"yyyyMMdd"];
    NSString *currentDateString = [df stringFromDate:[NSDate date]];
    
    NSArray *children = [self getItemsOnList:parentList.itemId];
    NSMutableArray *dueItems = [[NSMutableArray alloc]init];
    for (Item *eachItem in children){
        if (eachItem.done.intValue == 0) {
            NSString *dueDateString = [df stringFromDate:eachItem.duedate];
            if (dueDateString.intValue > 0 && dueDateString.intValue <= currentDateString.intValue) {
                [dueItems addObject:eachItem];
            }
        }
    }
    Item *itemInCell = [dueItems objectAtIndex:indexPath.row];
    
    cell.textLabel.text = itemInCell.title;
    cell.backgroundColor = [UIColor whiteColor];
    cell.textLabel.font = [UIFont fontWithName:@"Avenir" size:17];
    cell.textLabel.textColor = [UIColor blackColor];
    
    return cell;
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

-(NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewRowAction *deleteButton = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault title:@"DELETE" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath)
                                          {
                                              
                                              Item *itemToDelete = [self findItemAtIndexPath:indexPath];
                                              
                                              [DeleteItemFromServer deleteThisItem:itemToDelete];
                                              int timestamp = [[NSDate date] timeIntervalSince1970];
                                              NSString *date = [NSString stringWithFormat:@"%d", timestamp];
                                              [Intercom logEventWithName:@"Deleted_Item_From_DueItems_Screen" metaData: @{@"date": date}];
                                              
                                              [self.tableView reloadData];
                                          }];
    
    Item *parentList = [self.sectionsToShow objectAtIndex:indexPath.section];

    UIColor *color = [ColorHelper getUIColorFromString:parentList.color :1];
    deleteButton.backgroundColor = color;
    
    return @[deleteButton];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    // needs to exist for the "delete" buttons on left swipe
    
}

#pragma mark - Segues
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"showItemFromDue"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
        
        ItemVC *itemController = segue.destinationViewController;
        
        NSLog(@"indexpath clicked section = %ld, row = %ld", (long)indexPath.section, (long)indexPath.row);
        
        Item *list = [self.sectionsToShow objectAtIndex:indexPath.section];
        NSArray *itemsOnList = [self getItemsOnList:list.itemId];
        
        NSDateFormatter *df = [[NSDateFormatter alloc]init];
        [df setDateFormat:@"yyyyMMdd"];
        NSString *currentDateString = [df stringFromDate:[NSDate date]];
        
        NSMutableArray *dueItems = [[NSMutableArray alloc]init];
        for (Item *eachItem in itemsOnList){
            NSLog(@"items %@", eachItem.title);
            if (eachItem.done.intValue == 0) {
                NSString *dueDateString = [df stringFromDate:eachItem.duedate];
                if (dueDateString.intValue > 0 && dueDateString.intValue <= currentDateString.intValue) {
                    [dueItems addObject:eachItem];
                }
            }
        }
        
        
        Item *itemInCell = [dueItems objectAtIndex:indexPath.row];
        
        itemController.detailItem = itemInCell;
        itemController.parentList = list;

        
        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:self.navigationItem.backBarButtonItem.style target:nil action:nil];
        self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
        [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor]}];

        
    }
}


#pragma mark - Fetched results controller


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
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:context sectionNameKeyPath:nil cacheName:@"Master"];
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


#pragma mark - Helper methods


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
