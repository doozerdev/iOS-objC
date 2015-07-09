//
//  ParentCustomCell.h
//  Doozer
//
//  Created by Daniel Apone on 7/2/15.
//  Copyright (c) 2015 Daniel Apone. All rights reserved.
//

#import <UIKit/UIKit.h>
//#import <CoreData/CoreData.h>
#import "Item.h"

@interface ParentCustomCell : UITableViewCell

@property (nonatomic, strong) Item *itemInCell;

@property (nonatomic, weak) IBOutlet UITextField *cellItemTitle;
@property (nonatomic, weak) IBOutlet UILabel *cellItemSubTitle;

@property (weak, nonatomic) IBOutlet UIButton *RedButton;
@property (weak, nonatomic) IBOutlet UIButton *YellowButton;
@property (weak, nonatomic) IBOutlet UIButton *GreenButton;
@property (weak, nonatomic) IBOutlet UIButton *BlueButton;
@property (weak, nonatomic) IBOutlet UIButton *PurpleButton;


@end
