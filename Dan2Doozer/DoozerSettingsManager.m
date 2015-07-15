//
//  DoozerSettingsManager.m
//  Doozer
//
//  Created by Daniel Apone on 5/30/15.
//  Copyright (c) 2015 Daniel Apone. All rights reserved.
//

#import "DoozerSettingsManager.h"
#import "DoozerSyncManager.h"
#import "MasterViewController.h"
#import "AFNetworking.h"


@interface DoozerSettingsManager ()

@end

@implementation DoozerSettingsManager


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.UserNameLabel.text = [FBSDKProfile currentProfile].name;
    
    self.navigationController.navigationBar.barStyle  = UIBarStyleBlackTranslucent;
    self.navigationController.navigationBar.barTintColor = [UIColor darkGrayColor];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
