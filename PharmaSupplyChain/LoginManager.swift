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
    
    func storeUser(username: String, password: String, response: LoginObject?, rememberMe: Bool) {
        /* if "Remember Me" is set, store "username", "authToken" and "companyName" only */
        UserDefaults.standard.set(username, forKey: "username")
        if rememberMe {
            KeychainStore.storePassword(password: password)
        }
        if let response = response {
            if let companyName = response.user?.company?.name {
                UserDefaults.standard.set(companyName, forKey: "companyName")
            }
            if let authToken = response.token {
                UserDefaults.standard.set(authToken, forKey: "authToken")
            }
        }
    }
    
    func getUsername() -> String? {
        return UserDefaults.standard.string(forKey: "username")
    }
    
    func getPassword() -> String? {
        return KeychainStore.loadPassword()
    }
    
    func getCompanyName() -> String? {
        return UserDefaults.standard.string(forKey: "companyName")
    }
    
    func getAuthToken() -> String? {
        return UserDefaults.standard.string(forKey: "authToken")
    }
    
    func clear() {
        UserDefaults.standard.removeObject(forKey: "username")
        KeychainStore.clear()
        UserDefaults.standard.removeObject(forKey: "companyName")
        UserDefaults.standard.removeObject(forKey: "authToken")
    }
    
}
