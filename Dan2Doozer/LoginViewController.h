//
//  LoginViewController.h
//  Dan2Doozer
//
//  Created by Daniel Apone on 5/3/15.
//  Copyright (c) 2015 Daniel Apone. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>
#import <CoreData/CoreData.h>

@interface LoginViewController : UIViewController <NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *LoadingSpinner;
@property (weak, nonatomic) IBOutlet UILabel *LoginStatusLabel;
@property (weak, nonatomic) IBOutlet UILabel *welcome;
@property (weak, nonatomic) IBOutlet UILabel *toDoozer;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel1;
@property (weak, nonatomic) IBOutlet FBSDKLoginButton *loginButtonBackground;


@end
