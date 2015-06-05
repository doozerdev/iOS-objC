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
#import "Item.h"

@interface LoginViewController ()


@end

@implementation LoginViewController

NSString *sessionID = nil;


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.ConnectingTextLabel.text = @"Connecting to Doozer Server";
    self.ConnectingTextLabel.textColor = [UIColor lightGrayColor];
    
    if ([FBSDKAccessToken currentAccessToken]) {
        [self performSelector:@selector(logIntoDoozerWithFacebook) withObject:nil afterDelay:1];
    }
    else{
        [self performSelector:@selector(loginToFacebook) withObject:nil afterDelay:1];
    }
    
    NSMutableArray *newArrayOfItemsToUpdate = [[NSUserDefaults standardUserDefaults] valueForKey:@"itemsToUpdate"];
    
    NSLog(@"here's the items to update array = %@", newArrayOfItemsToUpdate);
        
    if(newArrayOfItemsToUpdate){
        //do nothing
    }else{
        //create the initial items to update array
        
        NSMutableArray *itemstoUpdate = [[NSMutableArray alloc]init];
        [[NSUserDefaults standardUserDefaults] setObject:itemstoUpdate forKey:@"itemsToUpdate"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}
                                                          
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)loginToFacebook {
    
    FBSDKLoginManager *login = [[FBSDKLoginManager alloc] init];
    [login logInWithReadPermissions:@[@"email"] handler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
        if (error) {
            // Process error
        } else if (result.isCancelled) {
            // Handle cancellations
        } else {
            
            [self logIntoDoozerWithFacebook];
            
            // If you ask for multiple permissions at once, you
            // should check if specific permissions missing
            if ([result.grantedPermissions containsObject:@"email"]) {
                // Do work
                
            }
        }
    }];
}

- (void)logIntoDoozerWithFacebook {
        
    if([FBSDKAccessToken currentAccessToken]){
        
        NSString *fbAccessToken = [[FBSDKAccessToken currentAccessToken] tokenString];
        NSString *startOfURL = @"http://warm-atoll-6588.herokuapp.com/api/login/";
        NSString *targetURL = [NSString stringWithFormat:@"%@%@", startOfURL, fbAccessToken];
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        [manager GET:targetURL parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
            sessionID = [responseObject objectForKey:@"sessionId"];
            self.ConnectingTextLabel.text = @"Connected!!";
            self.ConnectingTextLabel.textColor = [UIColor colorWithRed:0.52 green:0.76 blue:0.25 alpha:1.0];
            [[NSUserDefaults standardUserDefaults] setObject:sessionID forKey:@"UserLoginIdSession"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            //[self getDataFromDoozer];
            [self performSelector:@selector(showListList) withObject:nil afterDelay:1];
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Error: %@", error);
        }];
    }
}


- (void)showListList {
    [self performSegueWithIdentifier:@"showListList" sender:self];
}

#pragma mark - Segues


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([[segue identifier] isEqualToString:@"showListList"]) {
        
        MasterViewController *controller = (MasterViewController *)[[segue destinationViewController] topViewController];
        
        controller.managedObjectContext = self.managedObjectContext;
    }
}
 



@end
