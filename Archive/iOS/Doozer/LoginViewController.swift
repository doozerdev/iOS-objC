//
//  LoginViewController.swift
//  Doozer
//
//  Created by Greg Foltz on 2/8/15.
//  Copyright (c) 2015 Doozer Enterprise LLC. All rights reserved.
//

import Foundation


class LoginViewController : UIViewController, FBLoginViewDelegate
{
    func loginViewShowingLoggedInUser(loginView: FBLoginView)
    {
        DoozerSessionManager.sharedInstance.loginWithFacebook { (doozerSession, error) -> Void in
            if (error != nil || doozerSession == nil) {
                println("Error logging in to doozer: \(error)")
                let fbSession = FBSession.activeSession()
                if (fbSession != nil) {
                    fbSession.closeAndClearTokenInformation()
                }
            } else {
                self.presentingViewController?.dismissViewControllerAnimated(true, completion: nil);
            }
        }
    }
}