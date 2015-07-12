//
//  DoozerServiceClient.swift
//  Doozer
//
//  Created by Greg Foltz on 3/5/15.
//  Copyright (c) 2015 Doozer Enterprise LLC. All rights reserved.
//

import Foundation
public class DoozerRequestDefaults {
    class func baseUrl() -> String {
        return "http://\(DoozerRequestDefaults.domain())"
    }

    class func domain() -> String {
        return "warm-atoll-6588.herokuapp.com"
    }
}
public protocol DoozerRequestProtocol {
    typealias ResponseType
    func startWithCompletion(completion:(ResponseType?, NSError?) -> Void)
}

public class LoginRequest : DoozerRequestProtocol {
    typealias ResponseType = String

    let fbAccessToken : String!
    init(token: String!) {
        self.fbAccessToken = token
    }

    public func startWithCompletion(completion: (String?, NSError?) -> Void) {
        let manager = AFHTTPRequestOperationManager();
        manager.GET(
            "\(DoozerRequestDefaults.baseUrl())/api/login/\(self.fbAccessToken)",
            parameters: nil,
            success: { (operation, response) -> Void in
                let dict = response as? NSDictionary
                if (dict == nil) {
                    completion(nil, DoozerServiceClientError.LOGIN_RESPONSE_UNRECOGNIZED.toError())
                }

                let doozerSessionToken = dict!.objectForKey("session_id") as? String


                if (doozerSessionToken == nil) {
                    completion(nil, DoozerServiceClientError.LOGIN_RESPONSE_MISSING_TOKEN.toError())
                } else {
                    completion(doozerSessionToken, nil)
                }
            },
            failure: { (operation, error) -> Void in
                completion(nil, error)
            }
        )
    }
}

public class DoozerServiceClient {
    public func loginRequest(fbAccessToken: FBAccessTokenData!) -> LoginRequest {
        return LoginRequest(token:fbAccessToken.accessToken)
    }
}

public enum DoozerServiceClientError: Int {
    case LOGIN_RESPONSE_UNRECOGNIZED = 1
    case LOGIN_RESPONSE_MISSING_TOKEN = 2

    func toError() -> NSError {
        return NSError(domain:"DoozerServiceClientError", code:self.rawValue, userInfo: nil)
    }
}