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

@interface ItemVC () <UIGestureRecognizerDelegate, UITextViewDelegate>

@end

@implementation ItemVC


- (void)viewDidLoad {

    [super viewDidLoad];
    NSLog(@"start of view did load");
    
    self.ItemTitle.text = self.detailItem.title;
    
    if (self.detailItem.notes.length > 0 && ![self.detailItem.notes isEqualToString:@" "]) {
        self.Notes.text = self.detailItem.notes;
        self.Notes.font = [UIFont fontWithName:@"Avenir" size:17];
        self.Notes.textColor = [UIColor blackColor];

    }else{
        self.Notes.text = @"Add notes here...";
        self.Notes.font = [UIFont fontWithName:@"Avenir-Oblique" size:17];
        self.Notes.textColor = [UIColor lightGrayColor];
    }
    

    
    self.Notes.layer.borderWidth = 1.0f;
    self.Notes.layer.borderColor = [[UIColor lightGrayColor] CGColor];
    
    UIColor *themeColor = [ColorHelper getUIColorFromString:self.parentList.color :1];

    NSLog(@"item view loaded - 22222222!!!!!");
    
    self.view.backgroundColor = themeColor;
    
    NSLog(@"item view loaded - 33333!!!!!");

    
    self.navigationController.navigationBar.barStyle  = UIBarStyleBlack;
    self.navigationController.navigationBar.barTintColor = themeColor;
    

    
    self.showingDatePanel = NO;
    
    self.dateButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;

    self.dateButton.titleLabel.font = [UIFont fontWithName:@"Avenir-Heavy" size:17];
    self.dateButton2.titleLabel.font = [UIFont fontWithName:@"Avenir-Heavy" size:17];
    self.dateButton3.titleLabel.font = [UIFont fontWithName:@"Avenir-Heavy" size:17];
    self.dateButton4.titleLabel.font = [UIFont fontWithName:@"Avenir-Heavy" size:17];

    self.dateButton.tintColor = themeColor;
    self.dateButton2.tintColor = themeColor;
    self.dateButton3.tintColor = themeColor;
    self.dateButton4.tintColor = themeColor;
    

    
    if (self.detailItem.duedate) {
        
        
        NSDateFormatter *df = [[NSDateFormatter alloc]init];
        [df setDateFormat:@"EEE MMM dd, yyyy"];
        NSString * dateString = [df stringFromDate:self.detailItem.duedate];
        
        [self.dateButton setTitle: [NSString stringWithFormat:@"Due %@", dateString] forState: UIControlStateNormal];
        self.datePicker.date = self.detailItem.duedate;

    }else{
        [self.dateButton setTitle: @"Due Someday" forState: UIControlStateNormal];

    }
    [self.dateButton2 setTitle: @"Today" forState: UIControlStateNormal];
    [self.dateButton3 setTitle: @"Tomorrow" forState: UIControlStateNormal];
    [self.dateButton4 setTitle: @"Someday" forState: UIControlStateNormal];

    [self.datePicker addTarget:self
                        action:@selector(datePickerValueChanged:)
              forControlEvents:UIControlEventValueChanged];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [self.view addGestureRecognizer:tapGesture];
    
    self.ItemTitle.scrollEnabled = NO;
    self.Notes.scrollEnabled = YES;
    
    self.ItemTitle.font = [UIFont fontWithName:@"Avenir-Medium" size:22];
    
    NSLog(@"original titlefieldextraheight == === = = %f", self.titleFieldExtraHeight);
    
    
    UIImage *image = [UIImage imageNamed:@"outlinecircledone"];
    
    if (self.detailItem.done.intValue == 0) {
        self.toggleCompleteButton.backgroundColor = [UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:1];

    }else{
        self.toggleCompleteButton.backgroundColor = themeColor;
    }
    
    [self.toggleCompleteButton setBackgroundImage:image forState:UIControlStateNormal];
    
    
    NSLog(@"item view loaded - END!!!!!");

    
}


- (IBAction)toggleCompleteButtonPressed:(id)sender {


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
        self.toggleCompleteButton.backgroundColor = [ColorHelper getUIColorFromString:self.parentList.color :1];
        
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
        self.toggleCompleteButton.backgroundColor = [UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:1];
        
        
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
    
    [self.toggleCompleteButton setBackgroundImage:image forState:UIControlStateNormal];
    [self.toggleCompleteButton setBackgroundImage:image forState:UIControlStateHighlighted];


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

    
    if (![self.detailItem.title isEqualToString:self.ItemTitle.text] || (![self.detailItem.notes isEqualToString:self.Notes.text] && ![self.Notes.text isEqualToString:@"Add notes here..."])) {
        
        NSLog(@"saving Item on exit!");
        
        self.detailItem.notes = self.Notes.text;
        
        if (self.ItemTitle.text.length == 0) {
            //do nothing
        }else{
            self.detailItem.title = self.ItemTitle.text;
            [UpdateItemsOnServer updateThisItem:self.detailItem];
            int timestamp = [[NSDate date] timeIntervalSince1970];
            NSString *date = [NSString stringWithFormat:@"%d", timestamp];
            [Intercom logEventWithName:@"Edited_Item_Properties" metaData: @{@"date": date}];
        }
    }
    
    [super viewWillDisappear:animated];
}


-(void)textViewDidBeginEditing:(UITextView *)textView{
    
    if ([self.Notes.text isEqualToString:@"Add notes here..."]) {
        
        self.Notes.text = @"";
        self.Notes.font = [UIFont fontWithName:@"Avenir" size:17];
        self.Notes.textColor = [UIColor blackColor];
    }
    
    [self closeDatePanel];
    
}

-(void)textViewDidEndEditing:(nonnull UITextView *)textView{
    
    NSLog(@"ended editing!!");
    
    [self.view endEditing:YES];
}

- (void)textViewDidChange:(UITextView *)textView
{
    if (textView == self.ItemTitle) {
        CGFloat fixedWidth = textView.frame.size.width;
        CGSize newSize = [textView sizeThatFits:CGSizeMake(fixedWidth, MAXFLOAT)];
        CGRect newFrame = textView.frame;
        newFrame.size = CGSizeMake(fmaxf(newSize.width, fixedWidth), newSize.height);
        self.ItemTitle.frame = newFrame;
        
        self.titleFieldExtraHeight = newSize.height - 46.5;
        
    }
    NSLog(@"completed text feild editing");
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    
    if([text isEqualToString:@"\n"] && textView == self.ItemTitle) {
        [textView resignFirstResponder];
        return NO;
    }
    
    return YES;
}

-(void)handleTap:(UITapGestureRecognizer*)tapGesture {
    
    CGPoint location = [tapGesture locationInView:self.view];
    
    NSLog(@"location = %f,%f", location.x, location.y);
    
    [self.view endEditing:YES];
    
    if (location.y < 290) {
        [self closeDatePanel];
    }
    
}


-(void)viewDidLayoutSubviews {
        
    CGFloat fixedWidth = self.ItemTitle.frame.size.width;
    CGSize newSize = [self.ItemTitle sizeThatFits:CGSizeMake(fixedWidth, MAXFLOAT)];
    CGRect newFrame = self.ItemTitle.frame;
    newFrame.size = CGSizeMake(fmaxf(newSize.width, fixedWidth), newSize.height);
    self.ItemTitle.frame = newFrame;
    
    self.titleFieldExtraHeight = newSize.height - 46.5;
    
    CGRect currentFrame = self.upperViewPanel.frame;
    
    if (self.showingDatePanel) {
        CGRect newFrame = CGRectMake(currentFrame.origin.x, currentFrame.origin.y, currentFrame.size.width, 480 + self.titleFieldExtraHeight);
        self.upperViewPanel.frame = newFrame;

    }else{
        CGRect newFrame = CGRectMake(currentFrame.origin.x, currentFrame.origin.y, currentFrame.size.width, 225 + self.titleFieldExtraHeight);
        self.upperViewPanel.frame = newFrame;

    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)openDatePanel {
    
    CGRect currentFrame = self.upperViewPanel.frame;
    CGRect newFrame = CGRectMake(currentFrame.origin.x, currentFrame.origin.y, currentFrame.size.width, 480 + self.titleFieldExtraHeight);
    NSLog(@"opening the panel to == %f, %f, %f, %f", newFrame.origin.x, newFrame.origin.y, newFrame.size.width, newFrame.size.height);
    
    [UIView animateWithDuration:0.5f animations:^{
        self.upperViewPanel.frame = newFrame;
    } completion:^(BOOL finished) {
        self.showingDatePanel = YES;
        self.dateButton2.userInteractionEnabled = YES;
        self.dateButton3.userInteractionEnabled = YES;
        self.dateButton4.userInteractionEnabled = YES;
        
        [self.view endEditing:YES];

    }];
    
}

- (void)closeDatePanel {
    
    self.dateButton2.userInteractionEnabled = NO;
    self.dateButton3.userInteractionEnabled = NO;
    self.dateButton4.userInteractionEnabled = NO;
    
    self.showingDatePanel = NO;
    
    CGRect currentFrame = self.upperViewPanel.frame;
    CGRect newFrame = CGRectMake(currentFrame.origin.x, currentFrame.origin.y, currentFrame.size.width, 225+self.titleFieldExtraHeight);
    NSLog(@"closing the panel to == %f, %f, %f, %f", newFrame.origin.x, newFrame.origin.y, newFrame.size.width, newFrame.size.height);
    
    int timestamp = [[NSDate date] timeIntervalSince1970];
    NSString *date = [NSString stringWithFormat:@"%d", timestamp];
    [Intercom logEventWithName:@"Edited_Item_Properties" metaData: @{@"date": date}];
    
    [UIView animateWithDuration:0.5f animations:^{
        self.upperViewPanel.frame = newFrame;
    } completion:^(BOOL finished) {
        
        
    }];
}


- (IBAction)dateButtonPressed:(id)sender {
    
    //[self.view endEditing:YES];
    
    if (self.showingDatePanel) {
        
        self.detailItem.duedate = self.datePicker.date;
        
        [UpdateItemsOnServer updateThisItem:self.detailItem];
        
        [self closeDatePanel];
        
    }else{

        [self openDatePanel];
    }
}
    

- (IBAction)dateButton2Pressed:(id)sender {
    
    NSDate *today = [NSDate date];
        
    NSLog(@"today = %@", today);
    
    self.detailItem.duedate = today;
    
    NSDateFormatter *df = [[NSDateFormatter alloc]init];
    [df setDateFormat:@"EEE MMM dd, yyyy"];
    NSString * dateString = [df stringFromDate:today];
    
    [self.dateButton setTitle: [NSString stringWithFormat:@"Due %@", dateString] forState: UIControlStateNormal];

    self.datePicker.date = today;
    
    [UpdateItemsOnServer updateThisItem:self.detailItem];
    
    [self closeDatePanel];
}

- (IBAction)dateButton3Pressed:(id)sender {

    NSDateComponents *dayComponent = [[NSDateComponents alloc] init];
    dayComponent.day = 1;
    
    NSCalendar *theCalendar = [NSCalendar currentCalendar];
    NSDate *tomorrow = [theCalendar dateByAddingComponents:dayComponent toDate:[NSDate date] options:0];
    
    self.detailItem.duedate = tomorrow;
    
    NSDateFormatter *df = [[NSDateFormatter alloc]init];
    [df setDateFormat:@"EEE MMM dd, yyyy"];
    NSString * dateString = [df stringFromDate:tomorrow];
    
    self.datePicker.date = tomorrow;
    
    [self.dateButton setTitle: [NSString stringWithFormat:@"Due %@", dateString] forState: UIControlStateNormal];
    
    [UpdateItemsOnServer updateThisItem:self.detailItem];
    [self closeDatePanel];

    
}
- (IBAction)dateButton4Pressed:(id)sender {
    
    self.detailItem.duedate = nil;
    
    self.datePicker.date = [NSDate date];
    
    [self.dateButton setTitle: [NSString stringWithFormat:@"Due Someday"] forState: UIControlStateNormal];
    
    [UpdateItemsOnServer updateThisItem:self.detailItem];

    [self closeDatePanel];
    
    
}

- (void)datePickerValueChanged:(id)sender{
    
    
    NSDateFormatter *df = [[NSDateFormatter alloc]init];
    [df setDateFormat:@"EEE MMM dd, yyyy"];
    NSString * dateString = [df stringFromDate:self.datePicker.date];
    
    self.detailItem.duedate = self.datePicker.date;
    
    [self.dateButton setTitle: [NSString stringWithFormat:@"Due %@", dateString] forState: UIControlStateNormal];
    
    [UpdateItemsOnServer updateThisItem:self.detailItem];
    
}


@end
