//
//  ServerManager.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 25.10.16.
//  Copyright © 2016 Modum. All rights reserved.
//

import Alamofire
import SwiftyJSON
import Foundation

class ServerManager {
    
    // MARK: Constants
    
    fileprivate let API_URL = "https://core.modum.io/api/login"
    
    // MARK: Properties
    
    typealias AuthenticationToken = (String, Date)
    fileprivate var authenticationToken: AuthenticationToken?
    
    /*
     Given UserCredentials object and completionHandler, attempts to login the user with given credentials.
     If authentication was successful, executes completionHandler with no parameters
     Otherwise, executes completionHandler with the error occured.
    */
    func authenticateUser(WithUserCredentials userCredentials: UserCredentials, completionHandler: @escaping (AuthenticationError?) -> Void) {
        if let jsonUserCredentials = userCredentials.toJSON() {
            Alamofire.request(API_URL, method: .post, parameters: jsonUserCredentials, encoding: JSONEncoding.default, headers: nil).responseJSON(completionHandler: {
                [weak self]
                response in
                
                if let serverManager = self {
                    switch response.result {
                        case .success(let data):
                            let responseData = JSON(data)
                            if let authToken = responseData["token"].string, let expiryDateString = responseData["expire"].string, let expiryDate = date(FromServerString: expiryDateString) {
                                log("Received authentication token: \(authToken) with expiry date: \(expiryDate)")
                                serverManager.authenticationToken = AuthenticationToken(authToken, expiryDate)
                                completionHandler(nil)
                            } else if let errorCode = responseData["code"].int, let errorMessage = responseData["message"].string {
                                log("Received error \(errorCode): \(errorMessage)")
                                if errorMessage.compare("Incorrect Username / Password") == .orderedSame {
                                    completionHandler(AuthenticationError.InvalidCredentials)
                                } else {
                                    completionHandler(AuthenticationError.OtherProblem)
                                }
                            } else {
                                completionHandler(AuthenticationError.OtherProblem)
                            }
                        case .failure(let error):
                            log("Failed to parse JSON: \(error.localizedDescription)")
                            completionHandler(AuthenticationError.OtherProblem)
                    }
                }
            })
        }
    }
}
