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
import CoreData

class ServerManager {
    
    // MARK: Constants
    
    //fileprivate let API_URL = "https://core.modum.io/api/"
    fileprivate let API_URL = "http://dev.modum.io/api/"
    
    /* If date from the server-side is to set to nil, server automatically sets this value */
    static let serverNilDateString: String = "0001-01-01T00:34:08+00:34"
    
    // MARK: Properties
    
    fileprivate let coreDataManager: CoreDataManager
    
    fileprivate var authenticationToken: String? {
        return UserDefaults.standard.value(forKey: "authToken") as? String
    }
    
    /* User ID that can be extracted from authentication token */
    fileprivate var userID: Int?
    
    fileprivate var authorizationHeader: String? {
        return "Bearer " + (authenticationToken == nil ? "" : authenticationToken!)
    }
    
    init(WithCoreDataManager coreDataManager: CoreDataManager) {
        self.coreDataManager = coreDataManager
    }
    
    /*
     Given UserCredentials object and completionHandler, attempts to login the user with given credentials.
     If authentication was successful, executes completionHandler with no parameters
     Otherwise, executes completionHandler with the error occured.
    */
    func authenticateUser(WithCredentials loginCredentials: LoginCredentials, completionHandler: @escaping (AuthenticationError?) -> Void) {
        if let jsonLoginCredentials = loginCredentials.toJSON(), let parameters = ServerUtils.parameters(FromJSON: jsonLoginCredentials) {
            Alamofire.request(API_URL + "login", method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: nil).validate().responseJSON(completionHandler: {
                [weak self]
                response in
                
                if let serverManager = self {
                    switch response.result {
                        case .success(let data):
                            let responseData = JSON(data)
                            if let authToken = responseData["token"].string, let expiryDateString = responseData["expire"].string, let expiryDate = ServerUtils.date(FromServerString: expiryDateString) {
                                log("Received authentication token: \(authToken) with expiry date: \(expiryDate)")
                                
                                serverManager.userID = serverManager.extractUserID(FromAuthenticationToken: authToken)
                                
                                /* storing auth token and it's expiry date in UserDefaults*/
                                UserDefaults.standard.set(authToken, forKey: "authToken")
                                UserDefaults.standard.set(expiryDate, forKey: "authTokenExpiry")
                                UserDefaults.standard.synchronize()
                                
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
    
    /*
     Extracts user ID from authentication token
     If invalid authentication token is given, returns nil
     */
    fileprivate func extractUserID(FromAuthenticationToken authToken: String) -> Int? {
        let splitToken = authToken.characters.split(separator: ".").map(String.init)
        if let decodedData = splitToken[1].base64DecodedData() {
            let authTokenJson = JSON(data: decodedData)
            log("\(authTokenJson)")
            return authTokenJson["userId"].int
        } else {
            return nil
        }
    }
    
    /* */
    func getUserParcels(completionHandler: @escaping (_ success: Bool) -> Void) {
        if let authorizationHeader = authorizationHeader {
            Alamofire.request(API_URL + "v2/parcels/web", method: .get, parameters: nil, encoding: JSONEncoding.default, headers: ["Authorization" : authorizationHeader]).validate().responseJSON(completionHandler: {
                [weak self]
                response in
                
                if let serverManager = self {
                    switch response.result {
                    case .success(let data):
                        let responseData = JSON(data)
                        if let parcels = responseData.array {
                            for parcelJSON in parcels {
                                log("Received JSON for parcel: \(parcelJSON)")
                                let parcel = NSEntityDescription.insertNewObject(forEntityName: "Parcel", into: serverManager.coreDataManager.viewingContext) as! Parcel
                                parcel.fromJSON(object: parcelJSON)
                            }
                            serverManager.coreDataManager.saveLocally(managedContext: serverManager.coreDataManager.viewingContext)
                            completionHandler(true)
                        }
                    case .failure(let error):
                        log("Error is \(error.localizedDescription)")
                        completionHandler(false)
                    }
                }
            })
        } else {
            completionHandler(false)
        }
    }
    
}
