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

- (IBAction)SyncButton:(id)sender {
    
    if([FBSDKAccessToken currentAccessToken]){
        NSString *fbAccessToken = [[FBSDKAccessToken currentAccessToken] tokenString];
        NSString *startOfURL = @"http://warm-atoll-6588.herokuapp.com/api/login/";
        NSString *targetURL = [NSString stringWithFormat:@"%@%@", startOfURL, fbAccessToken];
        
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        [manager GET:targetURL parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
            
            NSString * sessionID = [responseObject objectForKey:@"sessionId"];
            [[NSUserDefaults standardUserDefaults] setObject:sessionID forKey:@"UserLoginIdSession"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            [DoozerSyncManager syncWithServer:self.managedObjectContext];
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Error: %@", error);
        }];

        NSDate * now = [NSDate date];
        [[NSUserDefaults standardUserDefaults] setObject:now forKey:@"LastSuccessfulSync"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        self.SyncStatusMessage.text = @"Background Sync initiated...";
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    NSDate *syncDate = [[NSUserDefaults standardUserDefaults] valueForKey:@"LastSuccessfulSync"];
    NSString *syncDateString = [NSString stringWithFormat:@"%@", syncDate];
    self.SyncCompleteLabel.text = syncDateString;
    self.SyncStatusMessage.text = nil;
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
