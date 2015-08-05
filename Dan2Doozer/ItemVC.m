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

@interface ItemVC () <UIGestureRecognizerDelegate, UITextViewDelegate>

@end

@implementation ItemVC



- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.ItemTitle.text = self.detailItem.title;
    
    CGFloat fixedWidth = self.ItemTitle.frame.size.width;
    CGSize newSize = [self.ItemTitle sizeThatFits:CGSizeMake(fixedWidth, MAXFLOAT)];
    CGRect newFrame = self.ItemTitle.frame;
    newFrame.size = CGSizeMake(fmaxf(newSize.width, fixedWidth), newSize.height);
    self.ItemTitle.frame = newFrame;
    
    self.titleFieldExtraHeight = newSize.height - 46.5;
    
    if (self.detailItem.notes.length > 0 && ![self.detailItem.notes isEqualToString:@" "]) {
        self.Notes.text = self.detailItem.notes;
        self.Notes.font = [UIFont fontWithName:@"Avenir-Medium" size:14];
        self.Notes.textColor = [UIColor blackColor];

    }else{
        self.Notes.text = @"Add notes here...";
        self.Notes.font = [UIFont fontWithName:@"Avenir-MediumOblique" size:14];
        self.Notes.textColor = [UIColor lightGrayColor];
    }
    
    self.Notes.layer.borderWidth = 1.0f;
    self.Notes.layer.borderColor = [[UIColor lightGrayColor] CGColor];
    
    self.ItemTitle.layer.borderWidth = 1.0f;
    self.ItemTitle.layer.borderColor = [[UIColor lightGrayColor] CGColor];
    
    UIColor *themeColor = [ColorHelper getUIColorFromString:self.parentList.color :1];

    self.view.backgroundColor = themeColor;
    self.showingDatePanel = NO;
    
    self.dateButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;

    self.dateButton.titleLabel.font = [UIFont fontWithName:@"Avenir-Heavy" size:16];
    self.dateButton2.titleLabel.font = [UIFont fontWithName:@"Avenir-Heavy" size:16];
    self.dateButton3.titleLabel.font = [UIFont fontWithName:@"Avenir-Heavy" size:16];
    self.dateButton4.titleLabel.font = [UIFont fontWithName:@"Avenir-Heavy" size:16];
    self.doneButton.titleLabel.font = [UIFont fontWithName:@"Avenir-Heavy" size:16];


    self.dateButton.tintColor = themeColor;
    self.dateButton2.tintColor = themeColor;
    self.dateButton3.tintColor = themeColor;
    self.dateButton4.tintColor = themeColor;
    self.doneButton.tintColor = themeColor;
    
    self.doneButton.hidden = YES;

    
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
        self.Notes.font = [UIFont fontWithName:@"Avenir-Medium" size:14];
        self.Notes.textColor = [UIColor blackColor];
    }
    
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
        textView.frame = newFrame;
        
        self.titleFieldExtraHeight = newSize.height - 46.5;
        
    }
    NSLog(@"completed text feild editing");
}

-(void)handleTap:(UITapGestureRecognizer*)tapGesture {
    
    NSLog(@"tap handler");
    
    CGPoint location = [tapGesture locationInView:self.view];
    
    NSLog(@"location = %f,%f", location.x, location.y);
    
    [self.view endEditing:YES];
    
    

}


-(void)viewDidLayoutSubviews {
    
    NSLog(@"layout sections");
    
    CGRect currentFrame = self.upperViewPanel.frame;

    if (self.showingDatePanel) {
        CGRect newFrame = CGRectMake(currentFrame.origin.x, currentFrame.origin.y, currentFrame.size.width, 455 + self.titleFieldExtraHeight);
        self.upperViewPanel.frame = newFrame;

    }else{
        CGRect newFrame = CGRectMake(currentFrame.origin.x, currentFrame.origin.y, currentFrame.size.width, 200 + self.titleFieldExtraHeight);
        self.upperViewPanel.frame = newFrame;

    }
    

    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)openDatePanel {
    
    CGRect currentFrame = self.upperViewPanel.frame;
    CGRect newFrame = CGRectMake(currentFrame.origin.x, currentFrame.origin.y, currentFrame.size.width, 455 + self.titleFieldExtraHeight);
    NSLog(@"opening the panel to == %f, %f, %f, %f", newFrame.origin.x, newFrame.origin.y, newFrame.size.width, newFrame.size.height);
    
    [UIView animateWithDuration:1.0f animations:^{
        self.upperViewPanel.frame = newFrame;
    } completion:^(BOOL finished) {
        self.showingDatePanel = YES;
        self.doneButton.hidden = NO;
        self.dateButton2.userInteractionEnabled = YES;
        self.dateButton3.userInteractionEnabled = YES;
        self.dateButton4.userInteractionEnabled = YES;
        self.doneButton.userInteractionEnabled = YES;

    }];
    
}

- (void)closeDatePanel {
    
    self.doneButton.hidden = YES;
    self.dateButton2.userInteractionEnabled = NO;
    self.dateButton3.userInteractionEnabled = NO;
    self.dateButton4.userInteractionEnabled = NO;
    self.doneButton.userInteractionEnabled = NO;
    
    self.showingDatePanel = NO;
    
    CGRect currentFrame = self.upperViewPanel.frame;
    CGRect newFrame = CGRectMake(currentFrame.origin.x, currentFrame.origin.y, currentFrame.size.width, 200+self.titleFieldExtraHeight);
    NSLog(@"closing the panel to == %f, %f, %f, %f", newFrame.origin.x, newFrame.origin.y, newFrame.size.width, newFrame.size.height);

    
    [UIView animateWithDuration:1.0f animations:^{
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

- (IBAction)doneButtonPressed:(id)sender {
    
    [self.view endEditing:YES];
    
    self.detailItem.duedate = self.datePicker.date;
    
    NSDateFormatter *df = [[NSDateFormatter alloc]init];
    [df setDateFormat:@"EEE MMM dd, yyyy"];
    NSString * dateString = [df stringFromDate:self.datePicker.date];
    
    [self.dateButton setTitle: [NSString stringWithFormat:@"Due %@", dateString] forState: UIControlStateNormal];


    [UpdateItemsOnServer updateThisItem:self.detailItem];
    
    [self closeDatePanel];
    
    
}
- (IBAction)dateButton2Pressed:(id)sender {
    
    NSDate *today = [NSDate date];
        
    NSLog(@"today = %@", today);
    
    self.detailItem.duedate = today;
    
    NSDateFormatter *df = [[NSDateFormatter alloc]init];
    [df setDateFormat:@"EEE MMM dd, yyyy"];
    NSString * dateString = [df stringFromDate:today];
    
    [self.dateButton setTitle: [NSString stringWithFormat:@"Due %@", dateString] forState: UIControlStateNormal];

    
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
    
    [self.dateButton setTitle: [NSString stringWithFormat:@"Due %@", dateString] forState: UIControlStateNormal];
    
    [UpdateItemsOnServer updateThisItem:self.detailItem];
    [self closeDatePanel];

    
}
- (IBAction)dateButton4Pressed:(id)sender {
    
    self.detailItem.duedate = nil;
    
    [self.dateButton setTitle: [NSString stringWithFormat:@"Due Someday"] forState: UIControlStateNormal];
    
    [UpdateItemsOnServer updateThisItem:self.detailItem];

    [self closeDatePanel];
    
    
}

- (void)datePickerValueChanged:(id)sender{
    
    
    NSDateFormatter *df = [[NSDateFormatter alloc]init];
    [df setDateFormat:@"EEE MMM dd, yyyy"];
    NSString * dateString = [df stringFromDate:self.datePicker.date];
    
    [self.dateButton setTitle: [NSString stringWithFormat:@"Due %@", dateString] forState: UIControlStateNormal];

    
}


@end
