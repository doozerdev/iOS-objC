//
//  AppDelegate.swift
//  Doozer
//
//  Created by Foltz, Greg on 6/3/14.
//  Copyright (c) 2014 Doozer Enterprise LLC. All rights reserved.
//

import UIKit
import CoreData


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
                            
    var window: UIWindow?
    var navController: UINavigationController?
    var homeViewController: HomeViewController?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: NSDictionary?) -> Bool {
        self.window?.makeKeyAndVisible();
     
        // Google Analytics
        GAI.sharedInstance().trackUncaughtExceptions = true;
        GAI.sharedInstance().dispatchInterval = 5;
        GAI.sharedInstance().logger.logLevel = GAILogLevel.Verbose;
        GAI.sharedInstance().trackerWithTrackingId("UA-58673990-1");
        
        // Startup Screen
        let tracker = GAI.sharedInstance().defaultTracker;
        tracker.set(kGAIScreenName, value: "Startup");
        tracker.send(GAIDictionaryBuilder.createScreenView().build());
        
        return true;

    }

    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String, annotation: AnyObject?) -> Bool {
        
        FBAppCall.handleOpenURL(url, sourceApplication: sourceApplication)
        return true;
    }
    
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        ItemMaster.sharedInstance.saveContext()
    }
}

