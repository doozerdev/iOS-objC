//
//  ItemCustomCell.h
//  Doozer
//
//  Created by Daniel Apone on 8/1/15.
//  Copyright © 2015 Daniel Apone. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ItemCustomCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UITextView *CellTextView;
@property (weak, nonatomic) IBOutlet UIButton *DoneButton;
@property (weak, nonatomic) IBOutlet UILabel *CellTextLabel;

@end
