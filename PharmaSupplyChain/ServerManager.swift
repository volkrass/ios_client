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
    
    /*
     Given UserCredentials object and completionHandler, attempts to login the user with given credentials.
     If authentication was successful, executes completionHandler with no parameters
     Otherwise, executes completionHandler with the error occured.
    */
    func authenticateUser(WithUserCredentials userCredentials: UserCredentials, completionHandler: @escaping (Error?) -> Void) {
        if let jsonUserCredentials = userCredentials.toJSON() {
            Alamofire.request(API_URL, method: .post, parameters: jsonUserCredentials, encoding: JSONEncoding.default, headers: nil).responseJSON(completionHandler: {
                response in
                
                switch response.result {
                    case .success(let data):
                        let responseData = JSON(data)
                        if let authToken = responseData["token"].string {
                            log("Received authentication token: \(authToken)")
                        }
                        completionHandler(nil)
                    case .failure(let error):
                        log("\(error)")
                        completionHandler(error)
                }
            })
        }
    }
    
}
