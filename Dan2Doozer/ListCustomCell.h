//
//  ListCustomCell.h
//  Doozer
//
//  Created by Daniel Apone on 7/6/15.
//  Copyright (c) 2015 Daniel Apone. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ListCustomCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UITextField *cellItemTitle;
@property (weak, nonatomic) IBOutlet UILabel *cellDueFlag;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *dueFlagBottomSpace;
@property (weak, nonatomic) IBOutlet UILabel *solutionsBadge;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *solutionsLabelTopSpacing;
@property (weak, nonatomic) IBOutlet UIImageView *lightBulb;




@end
