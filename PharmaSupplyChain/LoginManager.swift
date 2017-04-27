//
//  LoginManager.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 16.03.17.
//  Copyright © 2017 Modum. All rights reserved.
//

import Foundation

/* Singleton class response for storing user authentication data */
class LoginManager: NSObject {
    
    // MARK: Properties
    
    static let shared: LoginManager = LoginManager()
    
    // MARK: Public functions
    
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
            if let authTokenExpiry = response.expire {
                UserDefaults.standard.set(authTokenExpiry, forKey: "authTokenExpiry")
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
    
    func getAuthTokenExpiry() -> Date? {
        return UserDefaults.standard.object(forKey: "authTokenExpiry") as? Date
    }
    
    func clear() {
        if let bundle = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundle)
        }
        KeychainStore.clear()
    }
    
}
