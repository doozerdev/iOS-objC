//
//  DoozerSession.swift
//  Doozer
//
//  Created by Greg Foltz on 3/8/15.
//  Copyright (c) 2015 Doozer Enterprise LLC. All rights reserved.
//

import Foundation

public class DoozerSession {
    let token : String
    let accountName : String
    let userName : String

    init(accountName: String, token: String, userName: String) {
        self.accountName = accountName
        self.userName = userName
        self.token = token
    }
}

public class DoozerSessionManager {
    class var sharedInstance : DoozerSessionManager {
        struct Static {
            static let instance : DoozerSessionManager = DoozerSessionManager()
        }
        return Static.instance
    }

    let _settings : DoozerSettings
    let _serviceClient : DoozerServiceClient
    init() {
        _settings = DoozerSettings.sharedInstance
        _serviceClient = DoozerServiceClient()
    }

    public var activeSession : DoozerSession? {
        get {
            if (_activeSession == nil) {
                let (session, error) = loadCachedDoozerSession()
                if (error != nil) {
                    println("Error opening doozer session: \(error)")
                } else {
                    _activeSession = session
                }
            }
            return _activeSession
        }
    }
    var _activeSession : DoozerSession?

    public func loginWithFacebook(completion:(DoozerSession?, NSError?) -> Void) {
        if (FBSession.activeSession() == nil) {
            completion (nil, DoozerSessionManagerError.NO_FB_SESSION.toError())
            return
        }
        FBRequest.requestForMe().startWithCompletionHandler { (connection, userDict, error) -> Void in
            if (error != nil) {
                completion(nil, error)
                return
            }
            let fbUser = userDict as? NSDictionary
            if (fbUser == nil) {
                completion(nil, DoozerSessionManagerError.NO_FB_USER.toError())
                return
            }

            let fbUserID = userDict!.objectForKey("id") as? NSString
            let fbUserName = userDict!.objectForKey("name") as? NSString

            if (fbUserID == nil || fbUserName == nil) {
                completion(nil, DoozerSessionManagerError.NO_FB_USERDETAILS.toError())
                return
            }

            self.fetchDoozerAccessToken(
                FBSession.activeSession(),
                fbUserID:fbUserID!,
                fbUserName:fbUserName!,
                completion:completion
            )
        }
    }

    public func logout() {
        if (_activeSession == nil) {
            return
        }
        Locksmith.deleteDataForUserAccount(_activeSession!.accountName)
        _settings.activeAccount = nil
        _activeSession = nil

        println("=== DoozerSession Ended ===")
    }

    private func loadCachedFBSession() -> FBSession? {
        if (FBSession.activeSession() != nil || FBSession.openActiveSessionWithAllowLoginUI(false)) {
            return FBSession.activeSession();
        }
        return nil;
    }

    private func cacheDoozerSession(doozerSession : DoozerSession!) {
        let data = [
            "token": doozerSession.token,
            "user_name": doozerSession.userName
        ]
        Locksmith.saveData(data, forUserAccount: doozerSession.accountName)
        _settings.activeAccount = doozerSession.accountName
        _settings.save()
    }

    private func loadCachedDoozerSession() -> (DoozerSession?, NSError?) {
        let accountName = _settings.activeAccount

        if (accountName == nil) {
            return (nil, nil);
        }

        let (dictionary, error) = Locksmith.loadDataForUserAccount(accountName!)
        if (error != nil) {
            return (nil, error)
        }

        if (dictionary == nil) {
            return (nil, DoozerSessionManagerError.NO_DATA.toError())
        }

        let token = dictionary!.objectForKey("token") as String?
        let name = dictionary!.objectForKey("user_name") as String?

        if (token == nil) {
            return (nil, DoozerSessionManagerError.MISSING_TOKEN.toError())
        }

        if (name == nil) {
            return (nil, DoozerSessionManagerError.MISSING_ACCOUNT.toError())
        }

        return (DoozerSession(accountName: accountName!, token: token!, userName: name!), nil)
    }

    private func fetchDoozerAccessToken(
        fbSession : FBSession,
        fbUserID : String!,
        fbUserName : String!,
        completion : (DoozerSession?, NSError?) -> Void) {
            _serviceClient.loginRequest(fbSession.accessTokenData).startWithCompletion({
                (doozerToken, error) -> Void in
                if (error != nil) {
                    completion(nil, error)
                } else if (doozerToken == nil) {
                    completion(nil, DoozerSessionManagerError.MISSING_TOKEN.toError())
                } else {
                    let accountName = fbUserID
                    let doozerSession = DoozerSession(accountName: accountName, token:doozerToken!, userName:fbUserName)
                    self.cacheDoozerSession(doozerSession)
                    println("=== New DoozerSession for \(fbUserName) ===")
                    completion(doozerSession, nil)
                }
            })
    }

    public enum DoozerSessionManagerError: Int {
        case NO_DATA = 1
        case MISSING_TOKEN = 2
        case MISSING_ACCOUNT = 3
        case NO_FB_SESSION = 4
        case NO_FB_USERNAME = 5
        case NO_FB_USER = 6
        case NO_FB_USERDETAILS = 7

        func toError() -> NSError {
            return NSError(domain:"DoozerSessionManagerError", code:self.rawValue, userInfo: nil)
        }
    }
}