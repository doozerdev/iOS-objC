//
//  ItemVC.h
//  Doozer
//
//  Created by Daniel Apone on 8/3/15.
//  Copyright © 2015 Daniel Apone. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

#import "Item.h"

@interface ItemVC : UIViewController
@property (weak, nonatomic) IBOutlet UITextView *ItemTitle;
@property (weak, nonatomic) IBOutlet UITextView *Notes;
@property (weak, nonatomic) IBOutlet UIView *upperViewPanel;
@property (weak, nonatomic) IBOutlet UIButton *dateButton;
@property (weak, nonatomic) IBOutlet UIButton *dateButton2;
@property (weak, nonatomic) IBOutlet UIButton *dateButton3;
@property (weak, nonatomic) IBOutlet UIDatePicker *datePicker;
@property (weak, nonatomic) IBOutlet UIButton *dateButton4;
@property (weak, nonatomic) IBOutlet UIButton *toggleCompleteButton;


@property Item * detailItem;
@property Item * parentList;

@property float titleFieldExtraHeight;

@property BOOL showingDatePanel;


@end
