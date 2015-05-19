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
    
    
    if ([FBSDKAccessToken currentAccessToken]) {
        [self performSelector:@selector(logIntoDoozerWithFacebook) withObject:nil afterDelay:1];
    }
    else{
        [self performSelector:@selector(loginToFacebook) withObject:nil afterDelay:1];
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
            
            NSLog(@"oh yeah! Email!");
            
            [self logIntoDoozerWithFacebook];
            NSLog(@"Doozer should be logged in now");
            
            // If you ask for multiple permissions at once, you
            // should check if specific permissions missing
            if ([result.grantedPermissions containsObject:@"email"]) {
                // Do work
                
            }
        }
    }];
}



- (IBAction)buttonDoozerServer:(id)sender {
    
    [self logIntoDoozerWithFacebook];
    
}
- (IBAction)buttonGetMyLists:(id)sender {
    
    [self getDataFromDoozer];
}

- (void)logIntoDoozerWithFacebook {
        
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
            
            [self getDataFromDoozer];
            
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
            NSManagedObjectContext *context = _managedObjectContext;
            NSEntityDescription *entity = [NSEntityDescription entityForName:@"ItemRecord" inManagedObjectContext:self.managedObjectContext];
            NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
            [fetchRequest setEntity:entity];
            NSString *itemId = [eachArrayElement objectForKey:@"id"];
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"itemId == %@", itemId];
            [fetchRequest setPredicate:predicate];
            
            NSError *firsterror = nil;
            NSArray *results = [context executeFetchRequest:fetchRequest error:&firsterror];
            NSUInteger length = [results count];
            if (length == 0){
                NSString *title = [eachArrayElement objectForKey:@"title"];
                NSLog(@"%@", title);
                
                Item *newItem = [[Item alloc]initWithEntity:entity insertIntoManagedObjectContext:self.managedObjectContext];
                
                newItem.itemName = title;
                newItem.parentId = nil;
                newItem.itemId = itemId;
                
                // Save the context.
                NSError *error = nil;
                if (![context save:&error]) {
                    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
                    abort();
                }
            }
           
            NSNumber *children = [eachArrayElement objectForKey:@"children_count"];
           
            if (children!=0){
                NSString *getChildrenURL = [NSString stringWithFormat:@"http://warm-atoll-6588.herokuapp.com/api/items/%@/children", itemId];
                AFHTTPRequestOperationManager *dogs = [AFHTTPRequestOperationManager manager];
                [dogs.requestSerializer setValue:sessionID forHTTPHeaderField:@"sessionId"];
                [dogs GET:getChildrenURL parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
                
                NSDictionary *jsonChildrenDict = (NSDictionary *) responseObject;
                NSArray *fetchedChildrenArray = [jsonChildrenDict objectForKey:@"items"];
                    
                    for (id eachArrayElement in fetchedChildrenArray) {
                        NSManagedObjectContext *context = _managedObjectContext;
                        NSEntityDescription *entity = [NSEntityDescription entityForName:@"ItemRecord" inManagedObjectContext:self.managedObjectContext];
                        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
                        [fetchRequest setEntity:entity];
                        NSString *childId = [eachArrayElement objectForKey:@"id"];
                        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"itemId == %@", childId];
                        [fetchRequest setPredicate:predicate];
                        
                        NSError *firsterror = nil;
                        NSArray *results = [context executeFetchRequest:fetchRequest error:&firsterror];
                        NSUInteger length = [results count];
                        if (length == 0){
                            NSString *title = [eachArrayElement objectForKey:@"title"];
                            NSLog(@"%@", title);
                            
                            Item *newItem = [[Item alloc]initWithEntity:entity insertIntoManagedObjectContext:self.managedObjectContext];
                            
                            newItem.itemName = title;
                            newItem.parentId = itemId;
                            newItem.itemId = childId;
                            
                            // Save the context.
                            NSError *error = nil;
                            if (![context save:&error]) {
                                NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
                                abort();
                            }
                        }
                    }

                
                
                } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                     NSLog(@"Error: %@", error);
                }
                ];
            }
        }
        [self performSelector:@selector(showListList) withObject:nil afterDelay:1];
        
    }
     
    failure:^(AFHTTPRequestOperation *operation, NSError *error) {
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
