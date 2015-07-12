//
//  DoozerSettings.swift
//  Doozer
//
//  Created by Greg Foltz on 3/8/15.
//  Copyright (c) 2015 Doozer Enterprise LLC. All rights reserved.
//

import Foundation

public class DoozerSettings {

    class var sharedInstance : DoozerSettings {
        struct Static {
            static let instance : DoozerSettings = DoozerSettings()
        }
        return Static.instance
    }

    let _userDefaults : NSUserDefaults;

    init() {
        _userDefaults = NSUserDefaults.standardUserDefaults();
    }

    var activeAccount: String? {
        get {
            return _userDefaults.stringForKey("activeAccount")
        }

        set {
            _userDefaults.setObject(newValue, forKey: "activeAccount")
        }
    }

    public func save() {
        _userDefaults.synchronize()
    }
}