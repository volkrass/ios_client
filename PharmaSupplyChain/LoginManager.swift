//
//  LoginManager.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 16.03.17.
//  Copyright © 2017 Modum. All rights reserved.
//

import Foundation

class LoginManager: NSObject {
    
    static let shared: LoginManager = LoginManager()
    
    func storeUserCredentials(username: String, password: String, companyName: String? = nil) {
        UserDefaults.standard.set(username, forKey: "username")
        UserDefaults.standard.set(password, forKey: "pass")
        if let companyName = companyName {
            UserDefaults.standard.set(companyName, forKey: "companyName")
        }
    }
    
    func retrieveUserCredentials() -> (username: String, password: String, companyName: String?)? {
        let username = UserDefaults.standard.string(forKey: "username")
        let password = UserDefaults.standard.string(forKey: "pass")
        let companyName = UserDefaults.standard.string(forKey: "companyName")
        if let username = username, let password = password {
            return (username: username, password: password, companyName: companyName)
        } else {
            return nil
        }
    }
    
}
