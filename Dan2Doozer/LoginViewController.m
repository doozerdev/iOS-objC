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
#import "GetItemsFromDoozer.h"
#import "DoozerSyncManager.h"


@interface LoginViewController ()


@end

@implementation LoginViewController

NSString *sessionID = nil;


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    if ([FBSDKAccessToken currentAccessToken]) {
        [self performSelector:@selector(logIntoDoozerWithFacebook) withObject:nil afterDelay:1];
    }
    else{
        [self performSelector:@selector(loginToFacebook) withObject:nil afterDelay:1];
    }
    
    NSMutableArray *newArrayOfItemsToAdd = [[NSUserDefaults standardUserDefaults] valueForKey:@"itemsToAdd"];
    if(newArrayOfItemsToAdd){
        //do nothing
    }else{
        //create the initial items to add array
        NSMutableArray *itemsToAdd = [[NSMutableArray alloc]init];
        [[NSUserDefaults standardUserDefaults] setObject:itemsToAdd forKey:@"itemsToAdd"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    NSMutableArray *newArrayOfListsToAdd = [[NSUserDefaults standardUserDefaults] valueForKey:@"listsToAdd"];
    if(newArrayOfListsToAdd){
        //do nothing
    }else{
        //create the initial lists to add array
        NSMutableArray *listsToAdd = [[NSMutableArray alloc]init];
        [[NSUserDefaults standardUserDefaults] setObject:listsToAdd forKey:@"listsToAdd"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    NSMutableArray *newArrayOfItemsToUpdate = [[NSUserDefaults standardUserDefaults] valueForKey:@"itemsToUpdate"];
    if(newArrayOfItemsToUpdate){
        //do nothing
    }else{
        //create the initial items to update array
        NSMutableArray *itemsToUpdate = [[NSMutableArray alloc]init];
        [[NSUserDefaults standardUserDefaults] setObject:itemsToUpdate forKey:@"itemsToUpdate"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    NSMutableArray *newArrayOfItemsToDelete = [[NSUserDefaults standardUserDefaults] valueForKey:@"itemsToDelete"];
    if(newArrayOfItemsToDelete){
        //do nothing
    }else{
        //create the initial items to delete array
        NSMutableArray *itemsToDelete = [[NSMutableArray alloc]init];
        [[NSUserDefaults standardUserDefaults] setObject:itemsToDelete forKey:@"itemsToDelete"];
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
            
            [self.LoadingSpinner startAnimating];
            
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
        self.LoginStatusLabel.text = @"Connecting to Doozer server...";
        NSString *fbAccessToken = [[FBSDKAccessToken currentAccessToken] tokenString];
        NSString *startOfURL = @"http://warm-atoll-6588.herokuapp.com/api/login/";
        NSString *targetURL = [NSString stringWithFormat:@"%@%@", startOfURL, fbAccessToken];
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        [manager GET:targetURL parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
            
            self.LoginStatusLabel.text = @"Checking server for items...";
        
            sessionID = [responseObject objectForKey:@"sessionId"];
            [[NSUserDefaults standardUserDefaults] setObject:sessionID forKey:@"UserLoginIdSession"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            GetItemsFromDoozer *foo = [[GetItemsFromDoozer alloc] init];
            [foo getItemsOnServer:^(NSMutableArray * itemsBigArray) {
                NSManagedObjectContext *currentContext = self.managedObjectContext;
                [DoozerSyncManager copyFromServer :currentContext :itemsBigArray];
                
                [self performSelector:@selector(showListList) withObject:nil afterDelay:2];
                
            }];
            
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
