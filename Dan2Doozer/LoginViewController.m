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
#import "intercom.h"
#import "AppDelegate.h"
#import "AddItemsToServer.h"
#import "Constants.h"


@interface LoginViewController ()  <UIAlertViewDelegate> 
@property (weak, nonatomic) IBOutlet UIButton *loginButtonFacebook;

@end

@implementation LoginViewController

NSString *sessionID = nil;


- (IBAction)loginWithFacebookButton:(id)sender {
    NSLog(@"pressed login button");
    
    [FBSDKProfile enableUpdatesOnAccessTokenChange:YES];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(profileUpdated:) name:FBSDKProfileDidChangeNotification object:nil];
    FBSDKLoginManager *login = [[FBSDKLoginManager alloc] init];
    [login logInWithReadPermissions:@[@"public_profile" , @"email"] handler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
        
        if (error) {
            // Process error
        } else if (result.isCancelled) {
            // Handle cancellations
        } else {
            UIView *fbButton = [self.view viewWithTag:234];
            fbButton.hidden = YES;
            self.loginButtonFacebook.hidden = YES;
            self.LoadingSpinner.hidden = NO;
            self.welcome.hidden = YES;
            self.toDoozer.text = @"Doozer";
            self.LoginStatusLabel.hidden = YES;
            self.statusLabel1.text = @"Getting your lists...";

            [self.LoadingSpinner startAnimating];
            
            [self logIntoDoozerWithFacebook];
            
            // If you ask for multiple permissions at once, you
            // should check if specific permissions missing
            if ([result.grantedPermissions containsObject:@"email"]) {
                //do work
                
            }
        }
    }];
    
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    NSLog(@"the view loaded");
    self.LoadingSpinner.hidden = YES;
    [self setNeedsStatusBarAppearanceUpdate];
    
    self.view.backgroundColor = [UIColor colorWithRed:0  green:0.796  blue:0.925 alpha:1];
    self.loginButtonBackground.backgroundColor = [UIColor colorWithRed:0  green:0.796  blue:0.925 alpha:1];

    if ([FBSDKAccessToken currentAccessToken]) {
        [self performSelector:@selector(logIntoDoozerWithFacebook) withObject:nil afterDelay:1];
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
    NSNumber *colorPicker = [[NSUserDefaults standardUserDefaults] valueForKey:@"colorPicker"];
    if(colorPicker){
        //do nothing
    }else{
        //create the initial items to delete array
        NSNumber *colorPicker = [NSNumber numberWithInteger:0];
        [[NSUserDefaults standardUserDefaults] setObject:colorPicker forKey:@"colorPicker"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    NSNumber *lastDoozerAuth = [[NSUserDefaults standardUserDefaults] valueForKey:@"secondsSinceDoozerAuth"];
    if(lastDoozerAuth){
        //do nothing
    }else{
        //create the initial record of when logging in happened
        lastDoozerAuth = [NSNumber numberWithInteger:0];
        [[NSUserDefaults standardUserDefaults] setObject:lastDoozerAuth forKey:@"lastDoozerAuth"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)profileUpdated:(NSNotification *) notification{
    NSLog(@"User name: %@",[FBSDKProfile currentProfile].name);
    NSLog(@"User ID: %@",[FBSDKProfile currentProfile].userID);
    NSString *fbUserId = [FBSDKProfile currentProfile].userID;
    NSString *fbUserName = [FBSDKProfile currentProfile].name;
    
    if (fbUserId) {
        
        [Intercom registerUserWithUserId:fbUserId];
    
        [[[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:@{@"fields": @"email"}]
         startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
             
             if (!error) {
                 NSString *fbEmail = result[@"email"];
                 if (fbEmail) {
                     [Intercom updateUserWithAttributes:@{
                                                          @"name" : fbUserName,
                                                          @"email" : fbEmail
                                                          }];
                 }else{
                     [Intercom updateUserWithAttributes:@{
                                                          @"name" : fbUserName
                                                          }];
                 }
             }
         }];
    }
}



- (void)logIntoDoozerWithFacebook {
        
    if([FBSDKAccessToken currentAccessToken]){
        
        //[self performSelector:@selector(showListList) withObject:nil afterDelay:2];
        //self.LoginStatusLabel.text = @"Checking server for items...";
        
        
        NSString *fbAccessToken = [[FBSDKAccessToken currentAccessToken] tokenString];

        AppDelegate* appDelegate = [AppDelegate sharedAppDelegate];
        NSString *targetURL = [NSString stringWithFormat:@"%@login/%@", appDelegate.SERVER_URI, fbAccessToken];
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        [manager GET:targetURL parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
            
                    
            sessionID = [responseObject objectForKey:@"sessionId"];
            [[NSUserDefaults standardUserDefaults] setObject:sessionID forKey:@"UserLoginIdSession"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            GetItemsFromDoozer *foo = [[GetItemsFromDoozer alloc] init];
            [foo getItemsOnServer:^(NSMutableArray * itemsBigArray) {
                
                id firstItem = nil;
                if ([itemsBigArray count] > 0) {
                    firstItem = [itemsBigArray objectAtIndex:0];
                }
                if ([firstItem isKindOfClass:[NSString class]]) {
                    NSLog(@"it's a string (inside LoginVC) - %@", firstItem);
                    
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Ooops!"
                                                                    message:@"We're having trouble connecting to the server. You play around with the sample lists, while we keep trying the server in the background."
                                                                   delegate:self
                                                          cancelButtonTitle:@"OK"
                                                          otherButtonTitles:nil];
                    [alert show];
                    
                }else{
                
                    NSTimeInterval secondsSinceUnixEpoch = [[NSDate date]timeIntervalSince1970];
                    int secondsEpochInt = secondsSinceUnixEpoch;
                    NSNumber *secondsEpoch = [NSNumber numberWithInt:secondsEpochInt];
                    [[NSUserDefaults standardUserDefaults] setObject:secondsEpoch forKey:@"LastSuccessfulSync"];
                    NSLog(@"in login view controller. last sync value is being set to %@", secondsEpoch);
                    [[NSUserDefaults standardUserDefaults] synchronize];
                    
                    [DoozerSyncManager copyFromServer :itemsBigArray];
                    
                    [self performSelector:@selector(showListList) withObject:nil afterDelay:0];
                }
            }];
            
            [DoozerSyncManager getUpdatedSolutions];
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Error: %@", error);
            NSLog(@"login failed!!");
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Ooops!"
                                                            message:@"We're having trouble connecting to the server. You play around with the sample lists, while we keep trying the server in the background."
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
            
            
        }];
    }
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    // the user clicked OK
    if (buttonIndex == 0) {
        [self performSelector:@selector(showListList) withObject:nil afterDelay:0];
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
