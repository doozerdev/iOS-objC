//
//  WelcomeViewController.m
//  Doozer
//
//  Created by Daniel Apone on 5/9/15.
//  Copyright (c) 2015 Daniel Apone. All rights reserved.
//

#import "WelcomeViewController.h"
#import "LoginViewController.h"
#import "MasterViewController.h"

@interface WelcomeViewController ()

@end

@implementation WelcomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    if ([FBSDKAccessToken currentAccessToken]) {
        [self performSelector:@selector(showLists) withObject:nil afterDelay:1];
    }
    else{
        [self performSelector:@selector(showLoginView) withObject:nil afterDelay:1];
    }
    

 
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)showLists {
    [self performSegueWithIdentifier:@"showLists" sender:self];
}

- (void)showLoginView {
    [self performSegueWithIdentifier:@"showLoginView" sender:self];
}


#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([[segue identifier] isEqualToString:@"showLists"]) {
        
        MasterViewController *controller = (MasterViewController *)[[segue destinationViewController] topViewController];
        
        controller.managedObjectContext = self.managedObjectContext;
        
    }
    if ([[segue identifier] isEqualToString:@"showLoginView"]) {
        
        LoginViewController *controller = (LoginViewController *)[segue destinationViewController];
        
        controller.managedObjectContext = self.managedObjectContext;
        
    }
}

@end
