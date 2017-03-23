//
//  KeychainStore.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 23.03.17.
//  Copyright © 2017 Modum. All rights reserved.
//

import Foundation
import Security

/* Class that allows to securely store user-sensitive data in Keychain */
class KeychainStore : NSObject {
    
    // MARK: Constants
    
    fileprivate static let userAccount: String = "AuthUser"
    fileprivate static let passwordKey: String = "PasswordKey"
    
    fileprivate static let kSecClassGenericPasswordValue: NSString = NSString(format: kSecClassGenericPassword)
    fileprivate static let kSecClassValue: NSString = NSString(format: kSecClass)
    fileprivate static let kSecAttrServiceValue: NSString = NSString(format: kSecAttrService)
    fileprivate static let kSecAttrAccountValue: NSString = NSString(format: kSecAttrAccount)
    fileprivate static let kSecValueDataValue: NSString = NSString(format: kSecValueData)
    fileprivate static let kSecReturnDataValue: NSString = NSString(format: kSecReturnData)
    fileprivate static let kSecMatchLimitValue: NSString = NSString(format: kSecMatchLimit)
    fileprivate static let kSecMatchLimitOneValue: NSString = NSString(format: kSecMatchLimitOne)
    
    // MARK: Public functions
    
    /* Convinience function to store user password */
    public static func storePassword(password: String) {
        save(service: passwordKey, data: password)
    }
    
    /* Convinience function to retrieve user password from Keychain */
    public static func loadPassword() -> String? {
        return load(service: passwordKey)
    }
    
    /* Convinience function to delete existing password from Keychain */
    public static func clear() {
        delete(service: passwordKey)
    }
    
    // MARK: Helper functions
    
    /* Generic method to store @data String under given @service key */
    fileprivate static func save(service: String, data: String) {
        if let dataFromString = data.data(using: .utf8) {
            let keychainQuery = NSMutableDictionary(objects: [kSecClassGenericPasswordValue, service, userAccount, dataFromString], forKeys: [kSecClassValue, kSecAttrServiceValue, kSecAttrAccountValue, kSecValueDataValue])
            SecItemDelete(keychainQuery as CFDictionary)
            SecItemAdd(keychainQuery as CFDictionary, nil)
        }
    }
    
    /*
     Returns String if there exists an object in Keychain stored under @service key
     Otherwise, return nil
     */
    fileprivate static func load(service: String) -> String? {
        let keychainQuery = NSMutableDictionary(objects: [kSecClassGenericPasswordValue, service, userAccount, kCFBooleanTrue, kSecMatchLimitOneValue], forKeys: [kSecClassValue, kSecAttrServiceValue, kSecAttrAccountValue, kSecReturnDataValue, kSecMatchLimitValue])
        
        var dataTypeRef: AnyObject?
        
        let status = SecItemCopyMatching(keychainQuery, &dataTypeRef)
        var contentsOfKeychain: String? = nil
        
        if status == errSecSuccess {
            if let retrievedData = dataTypeRef as? Data {
                contentsOfKeychain = String(data: retrievedData, encoding: .utf8)
            }
        } else {
            log("Nothing was retrieved from the keychain. Status code \(status)")
        }
        
        return contentsOfKeychain
    }
    
    /*
     Deletes an object in Keychain stored under @service key if it exists
     Otherwise, does nothing
     */
    fileprivate static func delete(service: String) {
        let keychainQuery = NSMutableDictionary(objects: [kSecClassGenericPasswordValue, service, userAccount, kCFBooleanTrue, kSecMatchLimitOneValue], forKeys: [kSecClassValue, kSecAttrServiceValue, kSecAttrAccountValue, kSecReturnDataValue, kSecMatchLimitValue])
        SecItemDelete(keychainQuery)
    }
    
}
