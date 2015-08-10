
//
//  main.m
//  Dan2Doozer
//
//  Created by Daniel Apone on 5/1/15.
//  Copyright (c) 2015 Daniel Apone. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import "lecore.h"


int main(int argc, char * argv[]) {
    @autoreleasepool {
        
        le_init();
        le_set_token("059ad121-e3f3-4a5e-88a4-07278ab04900");
        
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
