//
//  ItemCustomCell.h
//  Doozer
//
//  Created by Daniel Apone on 9/21/15.
//  Copyright © 2015 Daniel Apone. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ItemCustomCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIButton *toggleButton;
@property (weak, nonatomic) IBOutlet UITextView *itemTitle;
@property (weak, nonatomic) IBOutlet UITextView *itemNotes;
@property (weak, nonatomic) IBOutlet UIButton *dateButton1;
@property (weak, nonatomic) IBOutlet UIButton *dateButton2;
@property (weak, nonatomic) IBOutlet UIButton *dateButton3;
@property (weak, nonatomic) IBOutlet UIButton *dateButton4;

@property (weak, nonatomic) IBOutlet UIDatePicker *datePicker;




@end
