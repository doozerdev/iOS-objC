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
            [[NSUserDefaults standardUserDefaults] setObject:sessionID forKey:@"UserLoginIdSession"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Error: %@", error);
        }];
        

        
    }
    
}


- (void)showListList {
    [self performSegueWithIdentifier:@"showListList" sender:self];
}


- (void)getDataFromDoozer {
    
    NSString *NewURL = @"http://warm-atoll-6588.herokuapp.com/api/items";
    
    AFHTTPRequestOperationManager *cats = [AFHTTPRequestOperationManager manager];
    [cats.requestSerializer setValue:sessionID forHTTPHeaderField:@"sessionId"];
    [cats GET:NewURL parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSDictionary *jsonDict = (NSDictionary *) responseObject;
        
        NSArray *fetchedArray = [jsonDict objectForKey:@"items"];
        
        for (id eachArrayElement in fetchedArray) {
            NSString *title = [eachArrayElement objectForKey:@"title"];
            NSLog(@"%@", title);
            
            NSManagedObjectContext *context = _managedObjectContext;
            NSEntityDescription *entity = [NSEntityDescription entityForName:@"ItemRecord" inManagedObjectContext:self.managedObjectContext];
            
            Item *newItem = [[Item alloc]initWithEntity:entity insertIntoManagedObjectContext:self.managedObjectContext];
            
            newItem.itemName = title;
            newItem.parentId = nil;
            
            // Save the context.
            NSError *error = nil;
            if (![context save:&error]) {
                NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
                abort();
            }
            
                }
        

        
        
        
        
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
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
