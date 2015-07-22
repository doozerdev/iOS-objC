//
//  WelcomeViewController.m
//  Doozer
//
//  Created by Daniel Apone on 6/4/15.
//  Copyright (c) 2015 Daniel Apone. All rights reserved.
//

#import "WelcomeViewController.h"
#import "MasterViewController.h"
#import "LoginViewController.h"
#import "DoozerSyncManager.h"
#import "intercom.h"

@interface WelcomeViewController ()

@end

@implementation WelcomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

-(void)viewDidAppear:(BOOL)animated{
    if ([FBSDKAccessToken currentAccessToken]) {
        NSString *fbUserId = [FBSDKProfile currentProfile].userID;
        [Intercom registerUserWithUserId:fbUserId];
        NSString *fbUserName = [FBSDKProfile currentProfile].name;        
        [Intercom updateUserWithAttributes:@{
                                             @"name" : fbUserName
                                             }];
        [self performSegueWithIdentifier:@"showMasterView" sender:self];
    
    }
    else{
        
        [self performSegueWithIdentifier:@"showLoginView" sender:self];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([[segue identifier] isEqualToString:@"showMasterView"]) {
                
        MasterViewController *controller = (MasterViewController *)[[segue destinationViewController] topViewController];
        
        controller.managedObjectContext = self.managedObjectContext;
        
        
    }
    if ([[segue identifier] isEqualToString:@"showLoginView"]) {
        
        LoginViewController *controller = (LoginViewController *)[segue destinationViewController];
        
        controller.managedObjectContext = self.managedObjectContext;
        
        
    }
}


@end
