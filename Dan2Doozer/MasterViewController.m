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
#import "AddItemsToServer.h"

@interface MasterViewController () <UITextFieldDelegate>


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
    
    [self rebalanceListOrdersIfNeeded];
    
    NSNumber *numberOfLaunches = [[NSUserDefaults standardUserDefaults] valueForKey:@"NumberOfLaunches"];
    if (numberOfLaunches.intValue == 0) {
        NSLog(@"first launch -- not syncing when loading main screen");
    }else{
        [DoozerSyncManager syncWithServer];
        
    }
    
    self.addingAnItem = NO;
    self.rowOfExpandedCell = -1;
    //self.rowOfNewItem = -1;
    
    //self.navigationController.hidesBarsOnSwipe = YES;
    
    
    // Do any additional setup after loading the view, typically from a nib.
    
    //self.navigationController.navigationBar.barStyle  = UIBarStyleBlackOpaque;
    //self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:0.77 green:0.4 blue:0.68 alpha:1.0];
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc]
                                               initWithTarget:self action:@selector(longPressGestureRecognized:)];
    [self.tableView addGestureRecognizer:longPress];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [self.tableView addGestureRecognizer:tapGesture];
    
    
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


- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    NSLog(@"text field is beginning editting");
    [textField performSelector:@selector(selectAll:) withObject:nil afterDelay:0.0];

    return YES;
}

// It is important for you to hide the keyboard
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];

    NSLog(@"text field ending editing");
    NSString *currentText = textField.text;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.rowOfExpandedCell inSection:0];
    
    Item *itemInCell = [self.fetchedResultsController objectAtIndexPath:indexPath];
    [self.view.window endEditing: YES];

    NSLog(@"index path of added cell = %@", indexPath);
    
    if (currentText.length == 0) {
        if (self.addingAnItem) {

            NSLog(@"deleting just created row");
            [context deleteObject:[self.fetchedResultsController objectAtIndexPath:indexPath]];
            self.addingAnItem = NO;
            
            NSError *error = nil;
            if (![context save:&error]) {
                NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
                abort();
            }
        }
        
    }else{
        itemInCell.title = currentText;

        [textField resignFirstResponder];

        NSLog(@"aboout to save the new list");

        if (self.addingAnItem) {
            [AddItemsToServer addThisItem:itemInCell];
            self.addingAnItem = NO;
        }else{
            [UpdateItemsOnServer updateThisItem:itemInCell];
        }
    }
    
    
    self.rowOfExpandedCell = -1;
    [self.tableView reloadData];
    //[self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];

    return YES;
}



- (void)addItemList {
    
    NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
    NSEntityDescription *entity = [[self.fetchedResultsController fetchRequest] entity];
    
    Item *newItem = [[Item alloc]initWithEntity:entity insertIntoManagedObjectContext:self.managedObjectContext];
    NSArray *itemArray = [self.fetchedResultsController fetchedObjects];
    int numberOfResults = (int)[itemArray count];
    self.rowOfExpandedCell = numberOfResults;
    
    if (numberOfResults == 0) {
        newItem.order = [NSNumber numberWithInt:65536];
    }else{
        Item *lastItem = [itemArray objectAtIndex:numberOfResults-1];
        newItem.order = [NSNumber numberWithInt:lastItem.order.intValue+65536];
    }
    
    newItem.parent = nil;
    //newItem.title = @" ";
    
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
    
    // Save the context.
    NSError *error = nil;
    if (![context save:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    self.addingAnItem = YES;
    
    NSIndexPath *newItemIndexPath = [NSIndexPath indexPathForRow:numberOfResults inSection:0];
    ParentCustomCell *cell = (ParentCustomCell *)[self.tableView cellForRowAtIndexPath:newItemIndexPath];
    cell.cellItemTitle.enabled = YES;
    cell.cellItemTitle.delegate = self;
    
    if (numberOfResults > 0) {
        for (int i = 0; i <= (int)numberOfResults; i++) {
            if (i != self.rowOfExpandedCell) {
                
                NSIndexPath *pathToLoad = [NSIndexPath indexPathForRow:i inSection:0];
                Item *itemToReload = [self.fetchedResultsController objectAtIndexPath:pathToLoad];
                itemToReload.forceUpdateString = @" ";
            }
        }
    }
    [cell.cellItemTitle becomeFirstResponder];
}



- (IBAction)addItemButton:(id)sender {
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Add a new item"
                                                    message:nil
                                                   delegate:self
                                          cancelButtonTitle:@"cancel"
                                          otherButtonTitles:nil];
    
    NSArray *listOfLists = self.fetchedResultsController.fetchedObjects;
    
    for(Item *eachList in listOfLists) {
        [alert addButtonWithTitle:eachList.title];
    }
    
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    [alert setTag:1];
    [alert textFieldAtIndex:0].autocorrectionType = UITextAutocorrectionTypeYes;
    [alert textFieldAtIndex:0].autocapitalizationType = UITextAutocapitalizationTypeSentences;
    
    [alert show];
    
}


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 1){
        
        int numberOfLists = (int)[self.fetchedResultsController.fetchedObjects count];
        
        //this is screwed up!!!
        
        
        
        NSLog(@"button index is %ld, and numberof lists is %d", (long)buttonIndex, numberOfLists);
        
        
        if (buttonIndex > numberOfLists || buttonIndex == 0) {
            NSLog(@"cancel was pressed");
        }else{
            
            NSString *currentText = [alertView textFieldAtIndex:0].text;
            if (currentText.length == 0) {
                NSLog(@"no text was entered in the fielf");
            }else{

                Item *targetList = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:buttonIndex-1 inSection:0]];
                NSLog(@"adding an item to list = %@", targetList.title);
                
                NSArray *itemsOnTargetList = [self fetchItemsOnList:targetList.itemId];
                
                NSEntityDescription *entity = [[self.fetchedResultsController fetchRequest] entity];
                
                Item *newItem = [[Item alloc]initWithEntity:entity insertIntoManagedObjectContext:self.managedObjectContext];
                
                newItem.title = currentText;
                
                long numberOfResults = [itemsOnTargetList count];
                
                if (numberOfResults == 0){
                    newItem.order = [NSNumber numberWithLong:16777216];
                }
                else{
                    Item *firstItemOnList = [itemsOnTargetList objectAtIndex:0];

                    newItem.order = [NSNumber numberWithInt:firstItemOnList.order.intValue/2];
                }
                
                newItem.done = 0;
                newItem.notes = @" ";
                newItem.parent = targetList.itemId;
                
                double timestamp = [[NSDate date] timeIntervalSince1970];
                newItem.itemId = [NSString stringWithFormat:@"%f", timestamp];
                
                [AddItemsToServer addThisItem:newItem];
                
                [self.tableView reloadData];
            }
            
        }
        
        
    }else if (alertView.tag == 2){
        if (buttonIndex == 1){
                        
            [DeleteItemFromServer deleteThisList:self.itemToDelete];
            self.itemToDelete = nil;
            
        }
    }

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
    
    ParentCustomCell *cell = (ParentCustomCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    
    switch (state) {
        case UIGestureRecognizerStateBegan: {
            
            //self.longPressActive = YES;
            
            if (indexPath) {
                    
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
            break;
        }
            
        case UIGestureRecognizerStateChanged: {
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
                        //self.showCompleted = YES;
                        int currentRow = (int)indexPath.row+1;
                        
                        NSMutableArray *indexPaths = [[NSMutableArray alloc]init];
                        for(int r = currentRow; r<totalRows; r++){
                            [indexPaths addObject:[NSIndexPath indexPathForRow:r inSection:0]];
                            
                            ParentCustomCell *cell = (ParentCustomCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:r inSection:0] ];
                            cell.hidden = NO;
                        }
                    }
                    // ... and update source so it is in sync with UI changes.
                    sourceIndexPath = indexPath;
                }
                break;
        }
            
        case UIGestureRecognizerStateEnded: {
                Item *reorderedItem = [self.fetchedResultsController.fetchedObjects objectAtIndex:_superOriginalIndex.row];
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

                
                [DoozerSyncManager syncWithServer];
                [self.tableView reloadData];
                
            }
            
        default: {
            // Clean up.

            ParentCustomCell *cell = (ParentCustomCell *)[self.tableView cellForRowAtIndexPath:sourceIndexPath];
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

-(void)rebalanceListOrdersIfNeeded{
    NSLog(@"inside rebalance list if needed method");
    
    NSArray *itemLists = self.fetchedResultsController.fetchedObjects;
    BOOL rebalanceNeeded = NO;
    int previousItemOrder = 0;
    for (Item *eachItem in itemLists){
        int diff = eachItem.order.intValue - previousItemOrder;
        previousItemOrder = eachItem.order.intValue;
        //NSLog(@"diff ===== %d", diff);
        if (diff < 256){
            rebalanceNeeded = YES;
        }
    }
    if (rebalanceNeeded) {
        [CoreDataItemManager rebalanceItemOrderValues:itemLists];
    }
    
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([[segue identifier] isEqualToString:@"showList"]) {
        
        //NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        NSIndexPath *indexPath = sender;
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
    int numOfRows = (int)[sectionInfo numberOfObjects];
    return numOfRows+1;
    
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"fetched items count = %lu, path = %@", (unsigned long)[self.fetchedResultsController.fetchedObjects count], indexPath);
    
    ParentCustomCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    cell.cellItemSubTitle.adjustsFontSizeToFitWidth = NO;
    cell.cellItemTitle.font = [UIFont systemFontOfSize:30];
    cell.cellItemTitle.textColor = [UIColor whiteColor];



    if (indexPath.row == [self.fetchedResultsController.fetchedObjects count]) {
        
        //NSLog(@"index path row = %ld", (long)indexPath.row);
        cell.cellItemSubTitle.hidden = YES;
        cell.cellItemTitle.textAlignment = NSTextAlignmentCenter;

        cell.cellItemTitle.text = [NSString stringWithFormat:@"\U0000254B\U0000FE0E"];

        cell.cellItemTitle.enabled = NO;
        cell.backgroundColor = [UIColor lightGrayColor];
        
        return cell;
        
    }else{
        
        Item *itemInCell = [self.fetchedResultsController objectAtIndexPath:indexPath];
        cell.itemInCell = itemInCell;
        cell.cellItemTitle.textAlignment = NSTextAlignmentLeft;


        NSNumber *launchCount = [[NSUserDefaults standardUserDefaults] valueForKey:@"NumberOfLaunches"];
        int numKids = 0;
        if ([launchCount intValue] == 0) {
            numKids = itemInCell.children_undone.intValue;
        }else{
            numKids = [CoreDataItemManager findNumberOfUncompletedChildren:itemInCell.itemId];
        }
        
        cell.cellItemTitle.text = itemInCell.title;
        //cell.cellItemTitle.text = [NSString stringWithFormat:@"%@ - %@", itemInCell.title, itemInCell.order];
        
        cell.cellItemSubTitle.hidden = NO;
        cell.cellItemSubTitle.text = [NSString stringWithFormat:@"%d Items", numKids];
        cell.cellItemSubTitle.textColor = [UIColor whiteColor];
        cell.cellItemSubTitle.font = [UIFont systemFontOfSize:15];
        cell.cellItemSubTitle.textAlignment = NSTextAlignmentLeft;
        
        if (self.rowOfExpandedCell == indexPath.row) {
            cell.RedButton.hidden = NO;
            cell.YellowButton.hidden = NO;
            cell.GreenButton.hidden = NO;
            cell.BlueButton.hidden = NO;
            cell.PurpleButton.hidden = NO;
            cell.cellItemTitle.enabled = YES;
            cell.cellItemTitle.delegate = self;
            [cell.cellItemTitle becomeFirstResponder];
            [cell.cellItemTitle performSelector:@selector(selectAll:) withObject:nil afterDelay:0.0];


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
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{

    if (indexPath.row == [self.fetchedResultsController.fetchedObjects count]){
        return 50;
    }else{
        if (self.rowOfExpandedCell == indexPath.row) {
            return 125;
        }else{
            return 75;
        }
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
    if (indexPath.row == [self.fetchedResultsController.fetchedObjects count]) {
        return NO;
    }else{
        return YES;
    }
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


-(void)handleTap:(UITapGestureRecognizer*)tapGesture; {
    CGPoint location = [tapGesture locationInView:self.tableView];
    
    NSLog(@"location = %f,%f", location.x, location.y);
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:location];
    
    NSLog(@"indexpath selected is = %@", indexPath);
    
    if (self.rowOfExpandedCell == -1) {
        if (indexPath.row == [self.fetchedResultsController.fetchedObjects count]) {
            [self addItemList];
        }else{
            [self performSegueWithIdentifier:@"showList" sender:indexPath];
        }
    }else{
        NSLog(@"row of expanded cell is %d", self.rowOfExpandedCell);
        if (indexPath.row != self.rowOfExpandedCell) {
            NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
            NSIndexPath *rowToSave = [NSIndexPath indexPathForRow:self.rowOfExpandedCell inSection:0];
            Item *itemToSave = [self.fetchedResultsController objectAtIndexPath:rowToSave];
            ParentCustomCell *cellToSave = (ParentCustomCell *)[self.tableView cellForRowAtIndexPath:rowToSave];
            NSString *currentText = cellToSave.cellItemTitle.text;
            
            if (self.addingAnItem) {
                if (currentText.length == 0){
                    NSLog(@"deleting just created row");
                    [context deleteObject:[self.fetchedResultsController objectAtIndexPath:rowToSave]];
                    
                    NSError *error = nil;
                    if (![context save:&error]) {
                        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
                        abort();
                    }
                }else{
                    itemToSave.title = currentText;
                    
                    [cellToSave.cellItemTitle resignFirstResponder];
                    [self.view.window endEditing: YES];
              
                    [AddItemsToServer addThisItem:itemToSave];
                }
                self.addingAnItem = NO;

            }else {
                if (currentText.length == 0) {
                    //discard teh zero lenght change
                }else{
                    itemToSave.title = currentText;
                    [UpdateItemsOnServer updateThisItem:itemToSave];
                    
                }
                [self.view.window endEditing: YES];
                [cellToSave.cellItemTitle resignFirstResponder];

            }
            self.rowOfExpandedCell = -1;
            [self.tableView reloadData];
        }
    }
}

/*
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    NSLog(@"indexpath selected is = %@", indexPath);
    
    if (self.rowOfExpandedCell == -1) {
        if (indexPath.row == [self.fetchedResultsController.fetchedObjects count]) {
            [self addItemList];
        }else{
            [self performSegueWithIdentifier:@"showList" sender:self];
        }
    }else{
        NSLog(@"row of expanded cell is %d", self.rowOfExpandedCell);
        if (indexPath.row != self.rowOfExpandedCell) {
            //Save item and reload table
            NSIndexPath *rowToSave = [NSIndexPath indexPathForRow:self.rowOfExpandedCell inSection:0];
            Item *itemToSave = [self.fetchedResultsController objectAtIndexPath:rowToSave];
            ParentCustomCell *cellToSave = (ParentCustomCell *)[self.tableView cellForRowAtIndexPath:rowToSave];
            itemToSave.title = cellToSave.cellItemTitle.text;
            
            [cellToSave.cellItemTitle resignFirstResponder];
            [self.view.window endEditing: YES];
            
            if (self.addingAnItem) {
                [AddItemsToServer addThisItem:itemToSave];
                self.addingAnItem = NO;
            }else{
                [UpdateItemsOnServer updateThisItem:itemToSave];
            }
            
            self.rowOfExpandedCell = -1;

            [self.tableView reloadData];
           
        }
    }
}
*/

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


- (NSArray *)fetchItemsOnList: (NSString *)parentID
{
    
    NSFetchRequest *fetchListRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"ItemRecord" inManagedObjectContext:self.managedObjectContext];
    [fetchListRequest setEntity:entity];
    
    // Set the batch size to a suitable number.
    [fetchListRequest setFetchBatchSize:20];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"parent == %@", parentID];
    [fetchListRequest setPredicate:predicate];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"order" ascending:YES];
    NSArray *sortDescriptors = @[sortDescriptor];
    
    [fetchListRequest setSortDescriptors:sortDescriptors];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    
    NSFetchedResultsController *lFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchListRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:@"FindList"];
    lFetchedResultsController.delegate = self;
    //self.fetchedResultsController = lFetchedResultsController;
    [NSFetchedResultsController deleteCacheWithName:@"FindList"];
    
    
    NSError *error = nil;
    if (![lFetchedResultsController performFetch:&error]) {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return lFetchedResultsController.fetchedObjects;
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

@end
