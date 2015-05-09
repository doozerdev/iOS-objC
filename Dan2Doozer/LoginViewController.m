//
//  LoginViewController.m
//  Dan2Doozer
//
//  Created by Daniel Apone on 5/3/15.
//  Copyright (c) 2015 Daniel Apone. All rights reserved.
//

#import "LoginViewController.h"
#import "AFNetworking.h"

static NSString * const BaseURLString = @"http://warm-atoll-6588.herokuapp.com/";

@interface LoginViewController ()

  

@end

@implementation LoginViewController



- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    NSString *fbAccessToken = [[FBSDKAccessToken currentAccessToken] tokenString];
    self.accessTokenTextField.text = fbAccessToken;
    
    NSString *startOfURL = @"http://warm-atoll-6588.herokuapp.com/api/login/";
    NSString *targetURL = [NSString stringWithFormat:@"%@%@", startOfURL, fbAccessToken];
    
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager GET:targetURL parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"JSON: %@", responseObject);
        
        NSString *sessionID = [responseObject objectForKey:@"sessionId"];
        
        self.doozerSessionIDTextField.text = sessionID;
    
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
   
    
    

    
    
    
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
