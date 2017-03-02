//
//  ServerManager.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 25.10.16.
//  Copyright © 2016 Modum. All rights reserved.
//

import Alamofire
import AlamofireObjectMapper
import Foundation
import SwiftyJSON
import CoreData

/* singleton */
class ServerManager {
    
    static let shared: ServerManager = ServerManager()
    
    // MARK: Constants
    
    fileprivate let CORE_API_URL = "https://core.modum.io/api/"
    fileprivate let DEV_API_URL = "http://dev.modum.io/api/"
    
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
    
    /* private initializer for singleton class */
    private init() {
        self.coreDataManager = CoreDataManager.shared
    }
    
    /*
     Given UserCredentials object and completionHandler, attempts to login with given credentials.
     If authentication was successful, executes completionHandler with no parameters
     Otherwise, executes completionHandler with the error occured.
    */
    func authenticateUser(username: String, password: String, completionHandler: @escaping (AuthenticationError?) -> Void) {
        Alamofire.request(CORE_API_URL + "login", method: .post, parameters: ["username" : username, "password" : password], encoding: JSONEncoding.default, headers: nil).validate().responseJSON(completionHandler: {
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
    
    /*
     Requests a list of user parcels from the server using http://dev.modum.io/api/v2/parcels/web
     - @completionHandler returns Error object if error occured and [Parcel] if parcels were successfully retrieved
     */
    func getUserParcels(completionHandler: @escaping (Error?, [Parcel]?) -> Void) {
        if let authorizationHeader = authorizationHeader {
            Alamofire.request(DEV_API_URL + "v2/parcels/web", method: .get, parameters: nil, encoding: JSONEncoding.default, headers: ["Authorization" : authorizationHeader]).validate().responseArray(completionHandler: {
                (response: DataResponse<[Parcel]>) -> Void in
                
                switch response.result {
                case .success:
                    completionHandler(nil, response.result.value)
                case .failure(let error):
                    log("Error is \(error.localizedDescription)")
                    completionHandler(error, nil)
                }
            })
        } else {
            completionHandler(nil, nil)
        }
    }
    
    /*
     Requests a list of temperature measurements for a parcel given @tntNumber and @sensorID parameters
     API call: http://dev.modum.io/api/parcels/<tntNumber>/<sensorID>/temperatures
     - @completionHandler returns Error object if error occured and [TemperatureMeasurement] if temperature measurements were successfully retrieved
     */
    func getTemperatureMeasurements(tntNumber: String, sensorID: String, completionHandler: @escaping (Error?, [TemperatureMeasurement]?) -> Void) {
        if let authorizationHeader = authorizationHeader {
            Alamofire.request(DEV_API_URL + "parcels/\(tntNumber)/\(sensorID)/temperatures", method: .get, parameters: nil, encoding: JSONEncoding.default, headers: ["Authorization" : authorizationHeader]).validate().responseArray(keyPath: "measurements", completionHandler: {
                (response: DataResponse<[TemperatureMeasurement]>) -> Void in
                
                switch response.result {
                case .success:
                    completionHandler(nil, response.result.value)
                case .failure(let error):
                    log("Error is \(error.localizedDescription)")
                    completionHandler(error, nil)
                }
            })
        } else {
            completionHandler(nil, nil)
        }
    }
    
    /*
     Requests a temperature measurements smart contract status for a parcel given @tntNumber and @sensorID parameters
     API call: http://dev.modum.io/api/parcels/<tntNumber>/<sensorID>/temperatures/status
     - @completionHandler returns Error object if error occured and SmartContractStatus object if it was returned
     */
    func getTemperatureMeasurementsStatus(tntNumber: String, sensorID: String, completionHandler: @escaping (Error?, SmartContractStatus?) -> Void) {
        if let authorizationHeader = authorizationHeader {
            Alamofire.request(DEV_API_URL + "parcels/\(tntNumber)/\(sensorID)/temperatures/status", method: .get, parameters: nil, encoding: JSONEncoding.default, headers: ["Authorization" : authorizationHeader]).validate().responseObject(completionHandler: {
                (response: DataResponse<SmartContractStatus>) -> Void in
                
                switch response.result {
                case .success:
                    completionHandler(nil, response.result.value)
                case .failure(let error):
                    log("Error is \(error.localizedDescription)")
                    completionHandler(error, nil)
                }
            })
        } else {
            completionHandler(nil, nil)
        }
    }
    
    /*
     Requests a prepared shipment for a specified Track-n-Trace number
     - @tntNumber: Track-N-Trace number of the shipment
     - @completionHandler: returns a boolean variable, indicating whether request was successful or not
     */
    func getPreparedShipment(tntNumber: String, completionHandler: @escaping (Error?, PreparedShipment?) -> Void) {
        if let authorizationHeader = authorizationHeader {
            Alamofire.request(DEV_API_URL + "preparedshipments/tntnumber/\(tntNumber)", method: .get, parameters: nil, encoding: JSONEncoding.default, headers: ["Authorization" : authorizationHeader]).validate().responseObject(completionHandler: {
                (response: DataResponse<PreparedShipment>) -> Void in
                
                switch response.result {
                case .success:
                    completionHandler(nil, response.result.value)
                case .failure(let error):
                    log("Error is \(error.localizedDescription)")
                    completionHandler(error, nil)
                }
            })
        } else {
            completionHandler(nil, nil)
        }
    }
    
    /*
     Requests a temperature measurements smart contract status for a parcel given @tntNumber and @sensorID parameters
     API call: http://dev.modum.io/api/parcels/<tntNumber>/<sensorID>/temperatures/status
     - @completionHandler returns Error object if error occured and SmartContractStatus object if it was returned
     */
    func getCompanyDefaults(completionHandler: @escaping (Error?, CompanyDefaults?) -> Void) {
        if let authorizationHeader = authorizationHeader {
            Alamofire.request(DEV_API_URL + "/v1/company/defaults", method: .get, parameters: nil, encoding: JSONEncoding.default, headers: ["Authorization" : authorizationHeader]).validate().responseObject(completionHandler: {
                (response: DataResponse<CompanyDefaults>) -> Void in
                
                switch response.result {
                case .success:
                    completionHandler(nil, response.result.value)
                case .failure(let error):
                    log("Error is \(error.localizedDescription)")
                    completionHandler(error, nil)
                }
            })
        } else {
            completionHandler(nil, nil)
        }
    }

    
    // MARK: Helper functions
    
    /*
     Extracts and returns user ID from authentication token
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
    
}
