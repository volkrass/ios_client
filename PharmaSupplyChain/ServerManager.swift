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
    
    func authenticateUser(WithUsername username: String, WithPassword password: String) {
        let parameters: [String: AnyObject] = [
            "Username" : username as AnyObject,
            "Password" : password as AnyObject
        ]
        
        Alamofire.request(API_URL, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: nil).responseJSON(completionHandler: {
            response in
            
            switch response.result {
                case .success(let data):
                    let responseData = JSON(data)
                    if let authToken = responseData["token"].string {
                        log("Received authentication token: \(authToken)")
                    }
                case .failure(let error):
                    log("\(error)")
            }
        })
    }
    
}
