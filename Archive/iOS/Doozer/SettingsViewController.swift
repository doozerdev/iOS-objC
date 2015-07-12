//
//  SettingsViewController.swift
//  Doozer
//
//  Created by Greg Foltz on 12/28/14.
//  Copyright (c) 2014 Doozer Enterprise LLC. All rights reserved.
//

import Foundation

class SettingsViewController: UIViewController, FBLoginViewDelegate
{
    
    @IBOutlet weak var profilePictureView: FBProfilePictureView!
    @IBOutlet weak var fbLoginView: FBLoginView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.fbLoginView.delegate = self;
    }
    func loginViewFetchedUserInfo(loginView: FBLoginView!, user: FBGraphUser!) {
        self.profilePictureView.profileID = user.objectID
    }
    
    func loginViewShowingLoggedOutUser(loginView: FBLoginView!) {
        if (self.profilePictureView.profileID != nil) {
            FBSession.activeSession().closeAndClearTokenInformation();
            ItemMaster.sharedInstance.clear();
            DoozerSessionManager.sharedInstance.logout()

            self.presentingViewController?.dismissViewControllerAnimated(true, completion: nil);

            self.profilePictureView.profileID = nil
            
            NSNotificationCenter.defaultCenter().postNotification(NSNotification(name: "DoozerLogout", object:nil));
        }
    }
    
    @IBAction func onCancel(sender: AnyObject) {
        self.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
}