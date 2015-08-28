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
#import "intercom.h"


@interface DoozerSettingsManager ()

@end

@implementation DoozerSettingsManager



- (IBAction)pressedLogOutButton:(id)sender {
    
    NSLog(@"user pressed the logout button");
    
    // This reset's the Intercom SDK's cache of your user's identity and wipes the slate clean.
    [Intercom reset];
    
    [[FBSDKLoginManager new] logOut];
    
}

- (IBAction)pressedPrivacyButton:(id)sender {
    NSLog(@"pressed PRIVACY button");
    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.doozer.tips/legal/privacy-policy.html"]];
    
}

- (IBAction)pressedTermsButton:(id)sender {
    
    NSLog(@"pressed TERMS button");

    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.doozer.tips/legal/Terms.html"]];

    
}

- (IBAction)pressedReviewButton:(id)sender {
    
    NSLog(@"pressed REVIEW button");

    
    NSString *iTunesLink = @"itms://itunes.apple.com/us/app/angry-birds/id343200656?mt=8";
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:iTunesLink]];
    
}

- (IBAction)pressedFeedbackButton:(id)sender {
    
    NSLog(@"pressed FEDDBACK button");

    
#define URLEMail @"mailto:info@doozer.tips?subject=Hey Doozer!&body=Here's what I think about..."
    
    NSString *url = [URLEMail stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding ];
    [[UIApplication sharedApplication]  openURL: [NSURL URLWithString: url]];
    
}

- (IBAction)pressedSupportButton:(id)sender {
    
    NSLog(@"pressed SUPPORT button");

    
#define URLEMail2 @"mailto:info@doozer.tips?subject=Help me!&body=I need help with..."
    
    NSString *url = [URLEMail2 stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding ];
    [[UIApplication sharedApplication]  openURL: [NSURL URLWithString: url]];
}



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
