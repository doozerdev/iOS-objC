//
//  ItemVC.m
//  Doozer
//
//  Created by Daniel Apone on 8/3/15.
//  Copyright © 2015 Daniel Apone. All rights reserved.
//

#import "ItemVC.h"
#import "ColorHelper.h"
#import "UpdateItemsOnServer.h"
#import "Intercom.h"
#import "CoreDataItemManager.h"
#import "AppDelegate.h"
#import "SolutionCustomCell.h"
#import "Solution.h"
#import "AFNetworking.h"
#import "Constants.h"
#import "DoozerSyncManager.h"
#import "ItemCustomCell.h"

@interface ItemVC () <UIGestureRecognizerDelegate, UITextViewDelegate>

@end

@implementation ItemVC


- (void)viewDidLoad {

    [super viewDidLoad];
    
    
    AppDelegate* appDelegate = [AppDelegate sharedAppDelegate];
    self.managedObjectContext = appDelegate.managedObjectContext;
    
    self.themeColor = [ColorHelper getUIColorFromString:self.parentList.color :1];

    self.view.backgroundColor = self.themeColor;
    
    self.solutionsTable.backgroundColor = self.themeColor;
    self.solutionsTable.separatorColor = self.themeColor;
    
    self.navigationController.navigationBar.barStyle  = UIBarStyleBlack;
    self.navigationController.navigationBar.barTintColor = self.themeColor;
    
    self.showingDatePanel = NO;
    
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [self.view addGestureRecognizer:tapGesture];
    
    
    self.hyperlinks = [[NSMutableArray alloc]init];
    
    if (self.detailItem.solutions.length > 5) {
        [self fetchSolutions];

    }
    
    [self markSolutionsViewed];
    
    [DoozerSyncManager getSolutions:self.detailItem];
    
    [self calculateCellRowHeights];
    
}


- (void)markSolutionsViewed{
    AppDelegate* appDelegate = [AppDelegate sharedAppDelegate];
    NSString *currentSessionId = [[NSUserDefaults standardUserDefaults] valueForKey:@"UserLoginIdSession"];
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager.requestSerializer setValue:currentSessionId forHTTPHeaderField:@"sessionId"];
    
    
    for (Solution *eachSolution in self.solutions) {
        
        NSString *URLstring = [NSString stringWithFormat:@"%@solutions/%@/view/%@", appDelegate.SERVER_URI, eachSolution.sol_ID, self.detailItem.itemId];
        
        //NSLog(@"here's the urlstring: %@", URLstring);
        
        [manager POST:URLstring parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSDictionary *serverResponse = (NSDictionary *)responseObject;
            //NSLog(@"heres the server response = %@", responseObject);
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Error: %@", error);
            
        }];
    }
    
}


- (IBAction)toggleCompleteButtonPressed:(id)sender {

    ItemCustomCell *cell = (ItemCustomCell *)[self.solutionsTable cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];

    NSArray *listArray = [self fetchEntireList];
    int indexOfCompletedHeader = 0;
    int loopcount = 0;
    for (Item *eachItem in listArray) {
        if ([eachItem.type isEqualToString:@"completed_header"]) {
            indexOfCompletedHeader = loopcount;
        }
        loopcount += 1;
    }
    Item *completedHeader = [listArray objectAtIndex:indexOfCompletedHeader];
    UIImage *image = [[UIImage alloc]init];
    
    int newOrder = 0;
 
    if (self.detailItem.done.intValue == 0) {
        self.detailItem.done = [NSNumber numberWithInt:1];
        image = [UIImage imageNamed:@"outlinecircledone"];
        cell.toggleButton.backgroundColor = [ColorHelper getUIColorFromString:self.parentList.color :1];
        
        if ([listArray count] - 1 > indexOfCompletedHeader) {
            Item *adjacentItem = [listArray objectAtIndex:indexOfCompletedHeader+1];
            newOrder = ((adjacentItem.order.intValue - completedHeader.order.intValue) / 2) + completedHeader.order.intValue;
        }else{
            newOrder = completedHeader.order.intValue + 100000000;
        }
        int timestamp = [[NSDate date] timeIntervalSince1970];
        NSString *date = [NSString stringWithFormat:@"%d", timestamp];
        [Intercom logEventWithName:@"Completed_Item_From_Item_Screen" metaData: @{@"date": date}];
        
    }else{
        self.detailItem.done = [NSNumber numberWithInt:0];
        image = [UIImage imageNamed:@"outlinecircledone"];
        cell.toggleButton.backgroundColor = [UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:1];
        
        
        if (indexOfCompletedHeader == 0) {
            
            newOrder = completedHeader.order.intValue / 2;
            
        }else{
            
            Item *adjacentItem = [listArray objectAtIndex:indexOfCompletedHeader-1];
            newOrder = ((completedHeader.order.intValue - adjacentItem.order.intValue) / 2) + adjacentItem.order.intValue;
        }
        int timestamp = [[NSDate date] timeIntervalSince1970];
        NSString *date = [NSString stringWithFormat:@"%d", timestamp];
        [Intercom logEventWithName:@"Uncompleted_Item_From_Item_Screen" metaData: @{@"date": date}];
    }
     
    self.detailItem.order = [NSNumber numberWithInt:newOrder];
    
    [cell.toggleButton setBackgroundImage:image forState:UIControlStateNormal];
    [cell.toggleButton setBackgroundImage:image forState:UIControlStateHighlighted];

    [self rebalanceListIfNeeded];
    [UpdateItemsOnServer updateThisItem:self.detailItem];

}



-(void)rebalanceListIfNeeded{
    //NSLog(@"inside rebalance list if needed method");
    
    NSArray *itemsOnList = [self fetchEntireList];
    
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

-(NSArray *)fetchEntireList{
    
    AppDelegate* appDelegate = [AppDelegate sharedAppDelegate];
    NSManagedObjectContext* context = appDelegate.managedObjectContext;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"ItemRecord" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    
    [fetchRequest setFetchBatchSize:20];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"parent == %@", self.detailItem.parent];
    [fetchRequest setPredicate:predicate];
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"order" ascending:YES];
    NSArray *sortDescriptors = @[sortDescriptor];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    NSFetchedResultsController *newFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:context sectionNameKeyPath:nil cacheName:@"ItemPage"];
    [NSFetchedResultsController deleteCacheWithName:@"ItemPage"];
    
    NSError *error = nil;
    if (![newFetchedResultsController performFetch:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return newFetchedResultsController.fetchedObjects;
    
}


-(void) viewWillDisappear:(BOOL)animated {

    ItemCustomCell *cell = (ItemCustomCell *)[self.solutionsTable cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    
    if (![self.detailItem.title isEqualToString:cell.itemTitle.text] || (![self.detailItem.notes isEqualToString:cell.itemNotes.text] && ![cell.itemNotes.text isEqualToString:@"Add notes here..."])) {
        
        NSLog(@"saving Item on exit!");
        
        self.detailItem.notes = cell.itemNotes.text;
        
        if (cell.itemTitle.text.length == 0) {
            //do nothing
        }else{
            self.detailItem.title = cell.itemTitle.text;
            [UpdateItemsOnServer updateThisItem:self.detailItem];
            int timestamp = [[NSDate date] timeIntervalSince1970];
            NSString *date = [NSString stringWithFormat:@"%d", timestamp];
            [Intercom logEventWithName:@"Edited_Item_Properties" metaData: @{@"date": date}];
        }
    }
    
    
    [super viewWillDisappear:animated];
}


-(void)textViewDidBeginEditing:(UITextView *)textView{

    ItemCustomCell *cell = (ItemCustomCell *)[self.solutionsTable cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];

    if ([cell.itemNotes.text isEqualToString:@"Add notes here..."]) {
        
        cell.itemNotes.text = @"";
        cell.itemNotes.font = [UIFont fontWithName:@"Avenir" size:17];
        cell.itemNotes.textColor = [UIColor blackColor];
    }
    
    [self closeDatePanel];
    
}

-(void)textViewDidEndEditing:(nonnull UITextView *)textView{
    
    NSLog(@"ended editing!!");
    
    [self.view endEditing:YES];
}

- (void)textViewDidChange:(UITextView *)textView
{
    ItemCustomCell *cell = (ItemCustomCell *)[self.solutionsTable cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];

    if (textView == cell.itemTitle) {
        
        self.detailItem.title = cell.itemTitle.text;
        
        CGRect screenRect = [[UIScreen mainScreen] bounds];
        CGSize newSize = [cell.itemTitle sizeThatFits:CGSizeMake(screenRect.size.width - 75, MAXFLOAT)];
        //value of 75 comes from main storyboard. it's the amount of horizontal space, both left and right, that is the itemTitle text view
        
        self.titleFieldExtraHeight = newSize.height - 46.5;
        //NSLog(@"completed text feild editing, and titleFieldExtraHeight is %f", self.titleFieldExtraHeight);

        
    }
    
    
    [self.solutionsTable beginUpdates];
    [self.solutionsTable endUpdates];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    
    ItemCustomCell *cell = (ItemCustomCell *)[self.solutionsTable cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];

    if([text isEqualToString:@"\n"] && textView == cell.itemTitle) {
        [textView resignFirstResponder];
        return NO;
    }
    
    return YES;
}

-(void)handleTap:(UITapGestureRecognizer*)tapGesture {
    
    CGPoint location = [tapGesture locationInView:self.view];
    
    //NSLog(@"location = %f,%f", location.x, location.y);
    
    [self.view endEditing:YES];
    
    if (location.y < 290) {
        [self closeDatePanel];
    }
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)openDatePanel {
    
    ItemCustomCell *cell = (ItemCustomCell *)[self.solutionsTable cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];

    self.showingDatePanel = YES;
    cell.dateButton2.userInteractionEnabled = YES;
    cell.dateButton3.userInteractionEnabled = YES;
    cell.dateButton4.userInteractionEnabled = YES;

    //NSLog(@"OPEN title field extra hieght is %f", self.titleFieldExtraHeight);
    
    [self.solutionsTable beginUpdates];
    [self.solutionsTable endUpdates];
    
}

- (void)closeDatePanel {
    
    ItemCustomCell *cell = (ItemCustomCell *)[self.solutionsTable cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];

    cell.dateButton2.userInteractionEnabled = NO;
    cell.dateButton3.userInteractionEnabled = NO;
    cell.dateButton4.userInteractionEnabled = NO;
    
    self.showingDatePanel = NO;
    
    //NSLog(@"CLOSE title field extra hieght is %f", self.titleFieldExtraHeight);

    
    [self.solutionsTable beginUpdates];
    [self.solutionsTable endUpdates];
}


- (IBAction)dateButtonPressed:(id)sender {
    
    NSLog(@"data button pressed");
    
    if (self.showingDatePanel) {
        
        //self.detailItem.duedate = self.datePicker.date;
        
        [UpdateItemsOnServer updateThisItem:self.detailItem];
        
        [self closeDatePanel];
        
    }else{

        [self openDatePanel];
    }
    
}
    

- (IBAction)dateButton2Pressed:(id)sender {
    ItemCustomCell *cell = (ItemCustomCell *)[self.solutionsTable cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];

    NSDate *today = [NSDate date];
    self.detailItem.duedate = today;
    
    NSDateFormatter *df = [[NSDateFormatter alloc]init];
    [df setDateFormat:@"EEE MMM dd, yyyy"];
    NSString * dateString = [df stringFromDate:today];
    
    [cell.dateButton1 setTitle: [NSString stringWithFormat:@"Due %@", dateString] forState: UIControlStateNormal];

    cell.datePicker.date = today;
    
    [UpdateItemsOnServer updateThisItem:self.detailItem];
    
    [self closeDatePanel];
}

- (IBAction)dateButton3Pressed:(id)sender {
    ItemCustomCell *cell = (ItemCustomCell *)[self.solutionsTable cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];

    NSDateComponents *dayComponent = [[NSDateComponents alloc] init];
    dayComponent.day = 1;
    
    NSCalendar *theCalendar = [NSCalendar currentCalendar];
    NSDate *tomorrow = [theCalendar dateByAddingComponents:dayComponent toDate:[NSDate date] options:0];
    
    self.detailItem.duedate = tomorrow;
    
    NSDateFormatter *df = [[NSDateFormatter alloc]init];
    [df setDateFormat:@"EEE MMM dd, yyyy"];
    NSString * dateString = [df stringFromDate:tomorrow];
    
    cell.datePicker.date = tomorrow;
    
    [cell.dateButton1 setTitle: [NSString stringWithFormat:@"Due %@", dateString] forState: UIControlStateNormal];
    
    [UpdateItemsOnServer updateThisItem:self.detailItem];
    [self closeDatePanel];

    
}
- (IBAction)dateButton4Pressed:(id)sender {
    
    ItemCustomCell *cell = (ItemCustomCell *)[self.solutionsTable cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];

    self.detailItem.duedate = nil;
    
    cell.datePicker.date = [NSDate date];
    
    [cell.dateButton1 setTitle: [NSString stringWithFormat:@"Due Someday"] forState: UIControlStateNormal];
    
    [UpdateItemsOnServer updateThisItem:self.detailItem];

    [self closeDatePanel];
    
    
}

- (void)datePickerValueChanged:(id)sender{
    
    ItemCustomCell *cell = (ItemCustomCell *)[self.solutionsTable cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    
    NSDateFormatter *df = [[NSDateFormatter alloc]init];
    [df setDateFormat:@"EEE MMM dd, yyyy"];
    NSString * dateString = [df stringFromDate:cell.datePicker.date];
    
    self.detailItem.duedate = cell.datePicker.date;
    
    [cell.dateButton1 setTitle: [NSString stringWithFormat:@"Due %@", dateString] forState: UIControlStateNormal];
    
    [UpdateItemsOnServer updateThisItem:self.detailItem];
    
}




- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return [self.solutions count] + 1;
}

- (void)calculateCellRowHeights {
    
    NSLog(@"calculating cell row heights");
    
    self.cellHeights = [[NSMutableArray alloc]init];
    
    for (int i = 0; i<[self.solutions count]+1; i++) {
        
        if (i == 0) {
            static NSString *MyIdentifier = @"firstCell";
            ItemCustomCell *cell = [self.solutionsTable dequeueReusableCellWithIdentifier:MyIdentifier];
            if (cell == nil) {
                cell = [[ItemCustomCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:MyIdentifier];
            }
            
            cell.itemTitle.font = [UIFont fontWithName:@"Avenir-Book" size:22];
            cell.itemTitle.text = self.detailItem.title;
            
            CGRect screenRect = [[UIScreen mainScreen] bounds];
            CGSize newSize = [cell.itemTitle sizeThatFits:CGSizeMake(screenRect.size.width - 75, MAXFLOAT)];
            //value of 75 comes from main storyboard. it's the amount of horizontal space, both left and right, that is the itemTitle text view
            
            self.titleFieldExtraHeight = newSize.height - 46.5;
            
            float cellHeight = 0;
            
            if (self.showingDatePanel) {
                
                cellHeight = 480 + self.titleFieldExtraHeight;
            }else{
                cellHeight = 225 + self.titleFieldExtraHeight;
            }
            //NSLog(@"returning %f for cell height of row %ld", cellHeight, (long)indexPath.row);
            [self.cellHeights addObject:[NSNumber numberWithFloat:cellHeight]];
            
        }else{
            
            //NSLog(@"solutions array is %@", self.solutions);
            //NSLog(@"i value is === %d", i);
            //NSLog(@"solutions count is ===%lu", (unsigned long)[self.solutions count]);
            
            static NSString *MyIdentifier = @"solutionCell";
            SolutionCustomCell *cell = [self.solutionsTable dequeueReusableCellWithIdentifier:MyIdentifier];
            if (cell == nil) {
                cell = [[SolutionCustomCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:MyIdentifier];
            }
            Solution *solutionInCell = [self.solutions objectAtIndex:i-1];
            //NSLog(@"chosen solutin is **************************************** %@", solutionInCell);
            
            cell.descriptionText.font = [UIFont fontWithName:@"Avenir-Book" size:12];
            cell.descriptionText.text = solutionInCell.sol_description;
            CGRect screenRect = [[UIScreen mainScreen] bounds];
            
            CGSize newSize = [cell.descriptionText sizeThatFits:CGSizeMake(screenRect.size.width - 25, MAXFLOAT)];
            //value of 40 comes from storyboard gaps on either side of the textfield
            
            //NSLog(@"cell desc width --- %f", cell.descriptionText.frame.size.width);
            
            float cellHeightOffset = newSize.height;
            //NSLog(@"solution --- %@", solutionInCell.sol_title);
            //NSLog(@"cell height offest is %f", cellHeightOffset);
            
            float size = screenRect.size.width / 4;
            
            if (solutionInCell.img_link) {
                cellHeightOffset += size;
                //NSLog(@"img height - offest is %f", cellHeightOffset);
                
            }else{
                cellHeightOffset += 30;
            }
            
            int count = 0;
            if (solutionInCell.phone_number) {
                if (solutionInCell.img_link) {
                    count += 1;
                }else{
                    cellHeightOffset += 30;
                }
                //NSLog(@"phone number - offest is %f", cellHeightOffset);
                
            }
            if (solutionInCell.address.length > 5) {
                if (solutionInCell.img_link) {
                    count += 1;
                }else{
                    cellHeightOffset += 30;
                }
                //NSLog(@"address - offest is %f, %@, %lu", cellHeightOffset, solutionInCell.address, (unsigned long)solutionInCell.address.length);
                
            }
            if (solutionInCell.open_hours) {
                if (solutionInCell.img_link) {
                    if (count > 1) {
                        cellHeightOffset += 30;
                    }
                    count += 1;
                }else{
                    cellHeightOffset += 30;
                }
                //NSLog(@"open hours - offest is %f", cellHeightOffset);
                
            }
            if (solutionInCell.price) {
                if (solutionInCell.img_link) {
                    if (count > 1) {
                        cellHeightOffset += 30;
                    }
                    count += 1;
                }else{
                    cellHeightOffset += 30;
                }
                //NSLog(@"price - offest is %f", cellHeightOffset);
                
            }
            //NSLog(@"final offest is %f", cellHeightOffset);
            
            [self.cellHeights addObject:[NSNumber numberWithFloat:cellHeightOffset + 120]];
        }
    }
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    
    //NSLog(@"heightForRowAtIndexPath is being called now for row %ld", (long)indexPath.row);
    
    NSNumber *returnValue = [self.cellHeights objectAtIndex:indexPath.row];
    
    return returnValue.floatValue;

    /*
    if (indexPath.row == 0) {
        static NSString *MyIdentifier = @"firstCell";
        ItemCustomCell *cell = [tableView dequeueReusableCellWithIdentifier:MyIdentifier];
        if (cell == nil) {
            cell = [[ItemCustomCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:MyIdentifier];
        }
        
        cell.itemTitle.font = [UIFont fontWithName:@"Avenir-Book" size:22];
        cell.itemTitle.text = self.detailItem.title;
        
        CGRect screenRect = [[UIScreen mainScreen] bounds];
        CGSize newSize = [cell.itemTitle sizeThatFits:CGSizeMake(screenRect.size.width - 75, MAXFLOAT)];
        //value of 75 comes from main storyboard. it's the amount of horizontal space, both left and right, that is the itemTitle text view

        self.titleFieldExtraHeight = newSize.height - 46.5;
        
        float cellHeight = 0;

        if (self.showingDatePanel) {

            cellHeight = 480 + self.titleFieldExtraHeight;
        }else{
            cellHeight = 225 + self.titleFieldExtraHeight;
        }
        //NSLog(@"returning %f for cell height of row %ld", cellHeight, (long)indexPath.row);
        return cellHeight;
        
    }else{
    
        static NSString *MyIdentifier = @"solutionCell";
        SolutionCustomCell *cell = [tableView dequeueReusableCellWithIdentifier:MyIdentifier];
        if (cell == nil) {
            cell = [[SolutionCustomCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:MyIdentifier];
        }
        Solution *solutionInCell = [self.solutions objectAtIndex:indexPath.row - 1];
        
        cell.descriptionText.font = [UIFont fontWithName:@"Avenir-Book" size:12];
        cell.descriptionText.text = solutionInCell.sol_description;
        CGRect screenRect = [[UIScreen mainScreen] bounds];

        CGSize newSize = [cell.descriptionText sizeThatFits:CGSizeMake(screenRect.size.width - 25, MAXFLOAT)];
        //value of 40 comes from storyboard gaps on either side of the textfield
        
        //NSLog(@"cell desc width --- %f", cell.descriptionText.frame.size.width);

        float cellHeightOffset = newSize.height;
        //NSLog(@"solution --- %@", solutionInCell.sol_title);
        //NSLog(@"cell height offest is %f", cellHeightOffset);
        
        float size = screenRect.size.width / 4;
        
        if (solutionInCell.img_link) {
            cellHeightOffset += size;
            //NSLog(@"img height - offest is %f", cellHeightOffset);
            
        }else{
            cellHeightOffset += 30;
        }
        
        int count = 0;
        if (solutionInCell.phone_number) {
            if (solutionInCell.img_link) {
                count += 1;
            }else{
                cellHeightOffset += 30;
            }
            //NSLog(@"phone number - offest is %f", cellHeightOffset);

        }
        if (solutionInCell.address.length > 5) {
            if (solutionInCell.img_link) {
                count += 1;
            }else{
            cellHeightOffset += 30;
            }
            //NSLog(@"address - offest is %f, %@, %lu", cellHeightOffset, solutionInCell.address, (unsigned long)solutionInCell.address.length);

        }
        if (solutionInCell.open_hours) {
            if (solutionInCell.img_link) {
                if (count > 1) {
                    cellHeightOffset += 30;
                }
                count += 1;
            }else{
                cellHeightOffset += 30;
            }
            //NSLog(@"open hours - offest is %f", cellHeightOffset);

        }
        if (solutionInCell.price) {
            if (solutionInCell.img_link) {
                if (count > 1) {
                    cellHeightOffset += 30;
                }
                count += 1;
            }else{
                cellHeightOffset += 30;
            }
            //NSLog(@"price - offest is %f", cellHeightOffset);

        }
        
        

        
        //NSLog(@"final offest is %f", cellHeightOffset);

        return cellHeightOffset + 120;
    }
     
     */
    
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.row == 0) {
        static NSString *MyIdentifier = @"firstCell";
        ItemCustomCell *cell = [tableView dequeueReusableCellWithIdentifier:MyIdentifier];
        if (cell == nil) {
            cell = [[ItemCustomCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:MyIdentifier];
        }
        
        cell.itemTitle.text = self.detailItem.title;
        cell.itemTitle.font = [UIFont fontWithName:@"Avenir-Book" size:22];

        
        if (self.detailItem.notes.length > 0 && ![self.detailItem.notes isEqualToString:@" "]) {
            cell.itemNotes.text = self.detailItem.notes;
            cell.itemNotes.font = [UIFont fontWithName:@"Avenir" size:17];
            cell.itemNotes.textColor = [UIColor blackColor];
            
        }else{
            cell.itemNotes.text = @"Add notes here...";
            cell.itemNotes.font = [UIFont fontWithName:@"Avenir-Oblique" size:17];
            cell.itemNotes.textColor = [UIColor lightGrayColor];
        }
        
        cell.itemNotes.layer.borderWidth = 1.0f;
        cell.itemNotes.layer.borderColor = [[UIColor lightGrayColor] CGColor];
        
        cell.dateButton1.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        
        cell.dateButton1.titleLabel.font = [UIFont fontWithName:@"Avenir-Heavy" size:17];
        cell.dateButton2.titleLabel.font = [UIFont fontWithName:@"Avenir-Heavy" size:17];
        cell.dateButton3.titleLabel.font = [UIFont fontWithName:@"Avenir-Heavy" size:17];
        cell.dateButton4.titleLabel.font = [UIFont fontWithName:@"Avenir-Heavy" size:17];
        
        cell.dateButton1.tintColor = self.themeColor;
        cell.dateButton2.tintColor = self.themeColor;
        cell.dateButton3.tintColor = self.themeColor;
        cell.dateButton4.tintColor = self.themeColor;
        
        if (self.detailItem.duedate) {
            
            
            NSDateFormatter *df = [[NSDateFormatter alloc]init];
            [df setDateFormat:@"EEE MMM dd, yyyy"];
            NSString * dateString = [df stringFromDate:self.detailItem.duedate];
            
            [cell.dateButton1 setTitle: [NSString stringWithFormat:@"Due %@", dateString] forState: UIControlStateNormal];
            cell.datePicker.date = self.detailItem.duedate;
            
        }else{
            [cell.dateButton1 setTitle: @"Due Someday" forState: UIControlStateNormal];
            
        }
        [cell.dateButton2 setTitle: @"Today" forState: UIControlStateNormal];
        [cell.dateButton3 setTitle: @"Tomorrow" forState: UIControlStateNormal];
        [cell.dateButton4 setTitle: @"Someday" forState: UIControlStateNormal];
        
        [cell.datePicker addTarget:self
                            action:@selector(datePickerValueChanged:)
                  forControlEvents:UIControlEventValueChanged];
        
        
        cell.itemTitle.scrollEnabled = NO;
        cell.itemNotes.scrollEnabled = YES;
        
        //cell.itemNotes.font = [UIFont fontWithName:@"Avenir-Medium" size:22];
        
        UIImage *image = [UIImage imageNamed:@"outlinecircledone"];
        
        if (self.detailItem.done.intValue == 0) {
            cell.toggleButton.backgroundColor = [UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:1];
            
        }else{
            cell.toggleButton.backgroundColor = self.themeColor;
        }
        
        [cell.toggleButton setBackgroundImage:image forState:UIControlStateNormal];
        
        
        return cell;

    }else{
    
        
        static NSString *MyIdentifier = @"solutionCell";
        SolutionCustomCell *cell = [tableView dequeueReusableCellWithIdentifier:MyIdentifier];
        if (cell == nil) {
            cell = [[SolutionCustomCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:MyIdentifier];
        }
        
        for (UIView *view in [cell.solutionsPanel subviews])
        {
            [view removeFromSuperview];
        }
        
        
        UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, cell.contentView.frame.size.width, 5)];
        
        lineView.backgroundColor = self.themeColor;
        [cell.contentView addSubview:lineView];
        
        Solution *solutionInCell = [self.solutions objectAtIndex:indexPath.row - 1];
        
        cell.descriptionText.font = [UIFont fontWithName:@"Avenir-Book" size:12];
        cell.descriptionText.text = solutionInCell.sol_description;
        CGRect oldSize = cell.descriptionText.frame;
        
        CGSize newSize = [cell.descriptionText sizeThatFits:CGSizeMake(oldSize.size.width, MAXFLOAT)];
        cell.descriptionText.frame = CGRectMake(oldSize.origin.x, oldSize.origin.y, oldSize.size.width, newSize.height);
        
        //NSLog(@"setting cell data for row %ld, with date of %@", (long)indexPath.row, solutionInCell.date_associated);
        
        cell.expertNameLabel.textColor = self.themeColor;
        cell.expertNameLabel.text = @"Daniel Apone";
        cell.expertTitleLabel.text = @"CEO, Doozer";

        cell.thumbsUp.tag = indexPath.row;
        cell.thumbsDown.tag = indexPath.row;
        
        if ([solutionInCell.state isEqualToString:@"liked"]) {
            cell.thumbsUp.backgroundColor = self.themeColor;
            cell.thumbsDown.backgroundColor = [UIColor clearColor];
        }else if ([solutionInCell.state isEqualToString:@"disliked"]){
            cell.thumbsUp.backgroundColor = [UIColor clearColor];
            cell.thumbsDown.backgroundColor = self.themeColor;
        }else{
            cell.thumbsDown.backgroundColor = [UIColor clearColor];
            cell.thumbsUp.backgroundColor = [UIColor clearColor];
        }
        
        CGRect screenRect = [[UIScreen mainScreen] bounds];
        
        float horizOffset = 0;
        
        if (solutionInCell.img_link) {
            //NSLog(@"%@", solutionInCell.img_link);

            UIImage *image = [self.images objectAtIndex:indexPath.row - 1];
            
            float size = screenRect.size.width / 4;
            UIImage *cropped = [[UIImage alloc]init];

            if (image.size.width > image.size.height) {
                
                double diff = (image.size.width - image.size.height) / 2.0;

                CGRect cropRect = CGRectMake(diff, 0, image.size.height, image.size.height);
                CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], cropRect);
                
                cropped = [UIImage imageWithCGImage:imageRef scale:0.0 orientation:UIImageOrientationUp];
                CGImageRelease(imageRef);


            }else{
                double diff = (image.size.height - image.size.width) / 2.0;
                
                CGRect cropRect = CGRectMake(0, diff, image.size.width, image.size.width);
                CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], cropRect);
                
                cropped = [UIImage imageWithCGImage:imageRef scale:0.0 orientation:UIImageOrientationUp];
                CGImageRelease(imageRef);
                
            }

            UIButton *imageButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
            [imageButton addTarget:self
                            action:@selector(solutionTitleButtonPressed:)
                  forControlEvents:UIControlEventTouchUpInside];
            imageButton.frame = CGRectMake(0, 0, size, size);
            imageButton.tag = indexPath.row;
            
            [imageButton setBackgroundImage:cropped forState:UIControlStateNormal];
        
            [cell.solutionsPanel addSubview:imageButton];

            horizOffset = size;
        }
        
        cell.solutionsPanel.layer.borderWidth = 2.0f;
        cell.solutionsPanel.layer.borderColor = [[UIColor lightGrayColor] CGColor];
        
        //create solutions title button
        UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [button addTarget:self
                   action:@selector(solutionTitleButtonPressed:)
         forControlEvents:UIControlEventTouchUpInside];
        
        [button setTitle:solutionInCell.sol_title forState:UIControlStateNormal];
        [button setTitleColor:self.themeColor forState:UIControlStateNormal];
        button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        button.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        button.titleLabel.font = [UIFont fontWithName:@"Avenir-Heavy" size:17];
        button.frame = CGRectMake(horizOffset + 10, 5, screenRect.size.width * .65, 30);
        button.tag = indexPath.row;
        [cell.solutionsPanel addSubview:button];
        float vertOffset = 30;

        if (solutionInCell.phone_number) {

            //NSLog(@"here's the phone number %@", solutionInCell.phone_number);
            UIButton *phoneButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
            [phoneButton addTarget:self
                       action:@selector(phoneButtonPressed:)
             forControlEvents:UIControlEventTouchUpInside];
            [phoneButton setTitle:solutionInCell.phone_number forState:UIControlStateNormal];
            [phoneButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
            phoneButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
            phoneButton.titleLabel.font = [UIFont fontWithName:@"Avenir" size:12];
            phoneButton.frame = CGRectMake(horizOffset + 10, vertOffset + 5, screenRect.size.width - 70, 30);
            phoneButton.tag = indexPath.row;
        
            [cell.solutionsPanel addSubview:phoneButton];
            vertOffset += 30;
            //NSLog(@"new vert offset is %f", vertOffset);
        }
        if (solutionInCell.address.length > 5) {

            //NSLog(@"here's the address %@", solutionInCell.address);
            UIButton *addressButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
            [addressButton addTarget:self
                            action:@selector(addressButtonPressed:)
                  forControlEvents:UIControlEventTouchUpInside];
            [addressButton setTitle:solutionInCell.address forState:UIControlStateNormal];
            [addressButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
            addressButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
            addressButton.titleLabel.font = [UIFont fontWithName:@"Avenir" size:12];
            addressButton.frame = CGRectMake(horizOffset + 10, vertOffset + 5, screenRect.size.width - 70, 30);
            addressButton.tag = indexPath.row;
            [cell.solutionsPanel addSubview:addressButton];
            vertOffset += 30;
            //NSLog(@"new vert offset is %f", vertOffset);
        }
        /*
        //if (solutionInCell.email) {
            //NSLog(@"here's the email %@", solutionInCell.email);
            UIButton *emailButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
            [emailButton addTarget:self
                              action:@selector(emailButtonPressed:)
                    forControlEvents:UIControlEventTouchUpInside];
            [emailButton setTitle:@"dan@doozer.tips" forState:UIControlStateNormal];
            [emailButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
            emailButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
            emailButton.titleLabel.font = [UIFont fontWithName:@"Avenir" size:12];
            emailButton.frame = CGRectMake(horizOffset + 10, vertOffset + 5, screenRect.size.width - 70, 30);
            emailButton.tag = indexPath.row;
            [cell.solutionsPanel addSubview:emailButton];
            vertOffset += 30;
            //NSLog(@"new vert offset is %f", vertOffset);
        //}
         */
        
        if (solutionInCell.open_hours) {
            //NSLog(@"setting open hours label");
            
            UILabel *hoursLabel = [[UILabel alloc]initWithFrame:CGRectMake(horizOffset + 10, vertOffset + 5, screenRect.size.width - 70, 30)];
            hoursLabel.textColor = [UIColor darkGrayColor];
            hoursLabel.text = solutionInCell.open_hours;
            hoursLabel.font = [UIFont fontWithName:@"Avenir" size:12];
            vertOffset += 30;
            //NSLog(@"new vert offset is %f", vertOffset);

            [cell.solutionsPanel addSubview:hoursLabel];

        }
        
        if (solutionInCell.price) {
            //NSLog(@"setting price label");
            
            UILabel *priceLabel = [[UILabel alloc]initWithFrame:CGRectMake(horizOffset + 10, vertOffset + 5, screenRect.size.width - 70, 30)];
            priceLabel.textColor = [UIColor darkGrayColor];
            priceLabel.text = [NSString stringWithFormat:@"$%@", solutionInCell.price.stringValue];
            priceLabel.font = [UIFont fontWithName:@"Avenir" size:12];
            vertOffset += 30;
            //NSLog(@"new vert offset is %f", vertOffset);
            
            [cell.solutionsPanel addSubview:priceLabel];
            
        }
        return cell;

    }
    
}

- (void)fetchSolutions{
    
    self.solutions = [[NSMutableArray alloc]init];
    self.images = [[NSMutableArray alloc]init];
    
    NSArray *array = [self.detailItem.solutions componentsSeparatedByString:@","];
    NSMutableArray *solutions = [[NSMutableArray alloc]init];
    
    for (NSString *solutionID in array){
        
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"SolutionRecord" inManagedObjectContext:self.managedObjectContext];
        [fetchRequest setEntity:entity];
        
        // Set the batch size to a suitable number.
        [fetchRequest setFetchBatchSize:20];
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"sol_ID == %@", solutionID];
        [fetchRequest setPredicate:predicate];
        
        
        // Edit the sort key as appropriate.
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"sol_ID" ascending:YES];
        NSArray *sortDescriptors = @[sortDescriptor];
        
        [fetchRequest setSortDescriptors:sortDescriptors];
        
        // Edit the section name key path and cache name if appropriate.
        // nil for section name key path means "no sections".
        NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:@"Solution"];
        [NSFetchedResultsController deleteCacheWithName:@"Solution"];
        
        NSError *error = nil;
        if (![aFetchedResultsController performFetch:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
        
        Solution *solution = [aFetchedResultsController.fetchedObjects objectAtIndex:0];
        
        [solutions addObject: solution];
    }
    
    
    NSSortDescriptor *sortDescriptor2;
    sortDescriptor2 = [[NSSortDescriptor alloc] initWithKey:@"date_associated" ascending:NO];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor2];
    NSArray *sortedSolutions;
    sortedSolutions = [solutions sortedArrayUsingDescriptors:sortDescriptors];
    
    [self.solutions addObjectsFromArray:sortedSolutions];
    
    //NSLog(@"solutions array is %@", self.solutions);
    
    int index = 0;

    for (Solution *eachSolution in self.solutions) {
        //NSLog(@"Index %d and the solutions image link = %@",index, eachSolution.img_link);
        
        if (eachSolution.img_link.length > 3) {
            //NSLog(@"image array index is = %d", index);
            
            __block UIImage *image = [[UIImage alloc]init];
            //NSLog(@"setting image placeholder at index %d", index);
            [self.images insertObject:image atIndex:index];
            
            dispatch_async(dispatch_get_global_queue(0,0), ^{
                NSData * data = [[NSData alloc] initWithContentsOfURL: [NSURL URLWithString: eachSolution.img_link]];
                if ( data == nil )
                    return;
                dispatch_async(dispatch_get_main_queue(), ^{
                    // WARNING: is the cell still using the same data by this point??
                    image = [UIImage imageWithData: data];
                    //NSLog(@"setting an image for index %d", index);
                    //NSLog(@"image data = %@", image);
                    if (image) {
                        [self.images replaceObjectAtIndex:index withObject:image];
                    }
                    image = nil;
                    [self.solutionsTable reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index+1 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
                    
                    //[self.solutionsTable reloadData];
                    //data = nil;
                });
            });
            
            
        }else{
            //NSLog(@"print that an image was skipped....");
            UIImage * image = [[UIImage alloc]init];
            [self.images insertObject:image atIndex:index];
            
        }
        
        index += 1;
    }

    
}

-(void)phoneButtonPressed:(UIButton *)button{
    Solution *solution = [self.solutions objectAtIndex:button.tag - 1];
    NSLog(@"hyperlink in phone button pressed - row %ld, value %@", (long)button.tag, solution.phone_number);
    
    NSString *URLString = [@"tel:" stringByAppendingString:solution.phone_number];
    
    NSURL *URL = [NSURL URLWithString:URLString];
    
    [[UIApplication sharedApplication] openURL:URL];

    
    
}

-(void)solutionTitleButtonPressed:(UIButton *)button{
    Solution *solution = [self.solutions objectAtIndex:button.tag - 1];
    NSLog(@"hyperlink in solutions pressed - row %ld, value %@", (long)button.tag, solution.link);
    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:solution.link]];
    
}

-(void)addressButtonPressed:(UIButton *)button{
    
    Solution *solution = [self.solutions objectAtIndex:button.tag - 1];
    NSLog(@"hyperlink in address pressed - row %ld, value %@", (long)button.tag, solution.address);
    
    NSString* addr = [NSString stringWithFormat:@"http://maps.apple.com/?q=%@",solution.address];
    NSURL* url = [[NSURL alloc] initWithString:[addr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    [[UIApplication sharedApplication] openURL:url];
}

-(void)emailButtonPressed:(UIButton *)button{
    
    //Solution *solution = [self.solutions objectAtIndex:button.tag];
    //NSLog(@"hyperlink in email pressed - row %ld, value %@", (long)button.tag, solution.email);
    
    #define URLEMail @"mailto:dan@doozer.tips?subject=Hey! Doozer sent me your way..."
    
    NSString *url = [URLEMail stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding ];
    [[UIApplication sharedApplication]  openURL: [NSURL URLWithString: url]];
    
}

- (IBAction)thumbsUpPressed:(UIButton *)button {
    
    int row = (int)button.tag;
    //NSLog(@"thumbs up pressed at row == %d", row);
    Solution *likedSolution = [self.solutions objectAtIndex:row - 1];
    AppDelegate* appDelegate = [AppDelegate sharedAppDelegate];
    
    NSString *URLstring = [NSString stringWithFormat:@"%@solutions/%@/like/%@", appDelegate.SERVER_URI, likedSolution.sol_ID, self.detailItem.itemId];
    
    NSString *currentSessionId = [[NSUserDefaults standardUserDefaults] valueForKey:@"UserLoginIdSession"];
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager.requestSerializer setValue:currentSessionId forHTTPHeaderField:@"sessionId"];
    
    [manager POST:URLstring parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSDictionary *serverResponse = (NSDictionary *)responseObject;
        //NSLog(@"heres the server response = %@", responseObject);
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
        
    }];
    
    likedSolution.state = @"liked";
    
    // Save the context.
    NSError *error = nil;
    if (![self.managedObjectContext save:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    [self.solutionsTable reloadData];
 
    
}

- (IBAction)thumbsDownPressed:(UIButton *)button {
    
    int row = (int)button.tag;

    NSLog(@"thumbs down pressed at row == %d", row);
    
    Solution *dislikedSolution = [self.solutions objectAtIndex:row - 1];
    AppDelegate* appDelegate = [AppDelegate sharedAppDelegate];
    NSString *URLstring = [NSString stringWithFormat:@"%@solutions/%@/dislike/%@", appDelegate.SERVER_URI, dislikedSolution.sol_ID, self.detailItem.itemId];
    
    NSString *currentSessionId = [[NSUserDefaults standardUserDefaults] valueForKey:@"UserLoginIdSession"];
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager.requestSerializer setValue:currentSessionId forHTTPHeaderField:@"sessionId"];
    
    [manager POST:URLstring parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSDictionary *serverResponse = (NSDictionary *)responseObject;
        NSLog(@"heres the server response = %@", responseObject);
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
        
    }];
    
    dislikedSolution.state = @"disliked";
    
    // Save the context.
    NSError *error = nil;
    if (![self.managedObjectContext save:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }

    [self.solutionsTable reloadData];

    
}


@end
