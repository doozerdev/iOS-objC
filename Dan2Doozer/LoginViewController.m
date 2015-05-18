//
//  LoginViewController.m
//  Dan2Doozer
//
//  Created by Daniel Apone on 5/3/15.
//  Copyright (c) 2015 Daniel Apone. All rights reserved.
//

#import "LoginViewController.h"
#import "AFNetworking.h"
#import "MasterViewController.h"

@interface LoginViewController ()


@end

@implementation LoginViewController

NSString *sessionID = nil;


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    
}
                                                          
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)buttonDoozerServer:(id)sender {
    
    [self logInWithFacebook];
    
}
- (IBAction)buttonGetMyLists:(id)sender {
    
    [self getDataFromDoozer];
}

- (void)logInWithFacebook {
        
    if([FBSDKAccessToken currentAccessToken]){
        
        NSString *fbAccessToken = [[FBSDKAccessToken currentAccessToken] tokenString];
        NSString *startOfURL = @"http://warm-atoll-6588.herokuapp.com/api/login/";
        NSString *targetURL = [NSString stringWithFormat:@"%@%@", startOfURL, fbAccessToken];
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        [manager GET:targetURL parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
            sessionID = [responseObject objectForKey:@"sessionId"];
            self.doozerSessionId.text = sessionID;
            NSLog(@"here is the first time session ID shows up = %@", sessionID);
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Error: %@", error);
        }];
        NSLog(@"here's session ID once again= %@", sessionID);
        
    }
    
}


- (void)showListList {
    [self performSegueWithIdentifier:@"showListList" sender:self];
}


- (void)getDataFromDoozer {
    
    NSString *NewURL = @"http://warm-atoll-6588.herokuapp.com/api/items";
    
    AFHTTPRequestOperationManager *cats = [AFHTTPRequestOperationManager manager];
    [cats.requestSerializer setValue:sessionID forHTTPHeaderField:@"sessionId"];
    
    NSLog(@"session ID = %@", sessionID);
    
    [cats GET:NewURL parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSString *itemsReturned = [responseObject objectForKey:@"items"];
        
        NSLog(@"spot 1");
        NSLog(@"%@", itemsReturned);
        NSLog(@"spot 2");
        
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"spot 3");
        NSLog(@"Error: %@", error);
        NSLog(@"spot 4");
    }];
    
}



#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([[segue identifier] isEqualToString:@"showListList"]) {
        
        MasterViewController *controller = (MasterViewController *)[[segue destinationViewController] topViewController];
        
        controller.managedObjectContext = self.managedObjectContext;
        
        
    }
}

- (IBAction)buttonLogInToDoozer:(UIButton *)sender {
}
@end
