//
//  SolutionCustomCell.h
//  Doozer
//
//  Created by Daniel Apone on 9/5/15.
//  Copyright (c) 2015 Daniel Apone. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SolutionCustomCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *expertNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *expertTitleLabel;
@property (weak, nonatomic) IBOutlet UITextView *descriptionText;
@property (weak, nonatomic) IBOutlet UILabel *solutionTitle;
@property (weak, nonatomic) IBOutlet UIView *solutionPanelLink;
@property (weak, nonatomic) IBOutlet UIButton *solutionLinkButton;




@end
