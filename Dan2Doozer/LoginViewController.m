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
            self.ConnectingTextLabel.text = @"Connected! Getting Items!";
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


- (void)getDataFromDoozer {
    NSString *NewURL = @"http://warm-atoll-6588.herokuapp.com/api/items";
    
    AFHTTPRequestOperationManager *cats = [AFHTTPRequestOperationManager manager];
    [cats.requestSerializer setValue:sessionID forHTTPHeaderField:@"sessionId"];
    [cats GET:NewURL parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSDictionary *jsonDict = (NSDictionary *) responseObject;
        NSArray *fetchedArray = [jsonDict objectForKey:@"items"];
        NSLog(@"HEre are the items from doozer server = %@", fetchedArray);
        
        
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
                NSString *ordertemp = [eachArrayElement objectForKey:@"order"];
                NSInteger ordertempInt = [ordertemp integerValue];
                NSNumber *order = [NSNumber numberWithInteger:ordertempInt];
                
                Item *newItem = [[Item alloc]initWithEntity:entity insertIntoManagedObjectContext:self.managedObjectContext];
                
                newItem.title = title;
                newItem.parent = nil;
                newItem.itemId = itemId;
                newItem.order = order;
                int r = arc4random_uniform(5);
                newItem.list_color = [NSNumber numberWithInt:r];
                
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
                        
                        //check to see if the item is already in local memory
                        NSError *firsterror = nil;
                        NSArray *results = [context executeFetchRequest:fetchRequest error:&firsterror];
                        NSUInteger length = [results count];
                        if (length == 0){
                            NSString *title = [eachArrayElement objectForKey:@"title"];
                            NSString *ordertemp = [eachArrayElement objectForKey:@"order"];
                            NSInteger ordertempInt = [ordertemp integerValue];
                            NSNumber *order = [NSNumber numberWithInteger:ordertempInt];
                            NSNumber *donetemp = [eachArrayElement objectForKey:@"done"];
                            NSString *notes = [eachArrayElement objectForKey:@"notes"];
                            NSString *duedateString = [eachArrayElement objectForKey:@"duedate"];
                            
                            Item *newItem = [[Item alloc]initWithEntity:entity insertIntoManagedObjectContext:self.managedObjectContext];
                            
                            NSDateFormatter* df = [[NSDateFormatter alloc]init];
                            [df setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZ"];
                            NSDate* duedate = [df dateFromString:duedateString];
                            
                            newItem.title = title;
                            newItem.parent = itemId;
                            newItem.itemId = childId;
                            newItem.order = order;
                            newItem.done = donetemp;
                            newItem.notes = notes;
                            newItem.duedate = duedate;
                            
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
 



@end
