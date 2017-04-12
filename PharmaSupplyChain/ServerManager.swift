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
import CoreData
import ReachabilitySwift

/* singleton */
class ServerManager {
    
    static let shared: ServerManager = ServerManager()
    
    // MARK: Constants
    
    fileprivate let CORE_API_URL = "https://core.modum.io/api/"
    fileprivate let DEV_API_URL = "http://dev.modum.io/api/"
    
    // MARK: Properties
    
    fileprivate let coreDataManager: CoreDataManager
    fileprivate let reachability: Reachability?
    
    fileprivate var authorizationHeader: String? {
        let authenticationToken = LoginManager.shared.getAuthToken()
        return "Bearer " + (authenticationToken == nil ? "" : authenticationToken!)
    }
    
    /* private initializer for singleton class */
    private init() {
        self.reachability = Reachability()
        self.coreDataManager = CoreDataManager.shared
    }
    
    /*
     Given UserCredentials object and completionHandler, attempts to login with given credentials.
     If authentication was successful, executes completionHandler with no parameters
     Otherwise, executes completionHandler with the error occured.
    */
    func login(username: String, password: String, completionHandler: @escaping (ServerError?, LoginObject?) -> Void) {
        if let reachability = reachability {
            if reachability.isReachable {
                Alamofire.request(DEV_API_URL + "login", method: .post, parameters: ["username" : username, "password" : password], encoding: JSONEncoding.default, headers: nil).validate().responseObject(completionHandler: {
                    (response: DataResponse<LoginObject>) -> Void in
                    
                    switch response.result {
                    case .success:
                        let loginObject = response.result.value
                        completionHandler(nil, loginObject)
                    case .failure(let error):
                        log("Error is \(error.localizedDescription)")
                        if let responseData = response.data, let errorResponseJSON = String(data: responseData, encoding: String.Encoding.utf8) {
                            var serverError = ServerError(JSONString: errorResponseJSON)
                            if serverError == nil {
                                serverError = ServerError.defaultError
                            }
                            completionHandler(serverError, nil)
                        } else {
                            completionHandler(ServerError.defaultError, nil)
                        }
                    }
                })
            } else {
                completionHandler(ServerError.noInternet, nil)
            }
        } else {
            completionHandler(ServerError.defaultError, nil)
        }
    }
    
    /*
     Requests a list of user parcels from the server using http://dev.modum.io/api/v2/parcels/web
     - @completionHandler returns Error object if error occured and [Parcel] if parcels were successfully retrieved
     */
    func getUserParcels(completionHandler: @escaping (ServerError?, [Parcel]?) -> Void) {
        if let reachability = reachability {
            if reachability.isReachable {
                if let authorizationHeader = authorizationHeader {
                    Alamofire.request(DEV_API_URL + "v2/parcels/web", method: .get, parameters: nil, encoding: JSONEncoding.default, headers: ["Authorization" : authorizationHeader]).validate().responseArray(completionHandler: {
                        (response: DataResponse<[Parcel]>) -> Void in
                        
                        switch response.result {
                        case .success:
                            completionHandler(nil, response.result.value)
                        case .failure(let error):
                            log("Error is \(error.localizedDescription)")
                            if let responseData = response.data, let errorResponseJSON = String(data: responseData, encoding: String.Encoding.utf8) {
                                var serverError = ServerError(JSONString: errorResponseJSON)
                                if serverError == nil {
                                    serverError = ServerError.defaultError
                                }
                                completionHandler(serverError, nil)
                            } else {
                                completionHandler(ServerError.defaultError, nil)
                            }
                        }
                    })
                } else {
                    completionHandler(ServerError.defaultError, nil)
                }
            } else {
                completionHandler(ServerError.noInternet, nil)
            }
        } else {
            completionHandler(ServerError.defaultError, nil)
        }
    }
    
    /*
     Requests a list of temperature measurements for a parcel given @tntNumber and @sensorID parameters
     API call: http://dev.modum.io/api/parcels/<tntNumber>/<sensorID>/temperatures
     - @completionHandler returns Error object if error occured and [TemperatureMeasurement] if temperature measurements were successfully retrieved
     */
    func getTemperatureMeasurements(tntNumber: String, sensorID: String, completionHandler: @escaping (ServerError?, [TemperatureMeasurement]?) -> Void) {
        if let reachability = reachability {
            if reachability.isReachable {
                if let authorizationHeader = authorizationHeader {
                    Alamofire.request(DEV_API_URL + "parcels/\(tntNumber)/\(sensorID)/temperatures", method: .get, parameters: nil, encoding: JSONEncoding.default, headers: ["Authorization" : authorizationHeader]).validate().responseArray(keyPath: "measurements", completionHandler: {
                        (response: DataResponse<[TemperatureMeasurement]>) -> Void in
                        
                        switch response.result {
                        case .success:
                            completionHandler(nil, response.result.value)
                        case .failure(let error):
                            log("Error is \(error.localizedDescription)")
                            if let responseData = response.data, let errorResponseJSON = String(data: responseData, encoding: String.Encoding.utf8) {
                                var serverError = ServerError(JSONString: errorResponseJSON)
                                if serverError == nil {
                                    serverError = ServerError.defaultError
                                }
                                completionHandler(serverError, nil)
                            } else {
                                completionHandler(ServerError.defaultError, nil)
                            }
                        }
                    })
                } else {
                    completionHandler(ServerError.defaultError, nil)
                }
            } else {
                completionHandler(ServerError.noInternet, nil)
            }
        } else {
            completionHandler(ServerError.defaultError, nil)
        }
    }
    
    /*
     Requests smart contract status for a parcel given @tntNumber and @sensorID parameters
     API call: http://dev.modum.io/api/parcels/<tntNumber>/<sensorID>/temperatures/status
     - @completionHandler returns Error object if error occured and SmartContractStatus object if it was returned
     */
    func getTemperatureMeasurementsStatus(tntNumber: String, sensorID: String, completionHandler: @escaping (ServerError?, SmartContractStatus?) -> Void) {
        if let reachability = reachability {
            if reachability.isReachable {
                if let authorizationHeader = authorizationHeader {
                    Alamofire.request(DEV_API_URL + "parcels/\(tntNumber)/\(sensorID)/temperatures/status", method: .get, encoding: JSONEncoding.default, headers: ["Authorization" : authorizationHeader]).validate().responseObject(completionHandler: {
                        (response: DataResponse<SmartContractStatus>) -> Void in
                        
                        switch response.result {
                        case .success:
                            completionHandler(nil, response.result.value)
                        case .failure(let error):
                            log("Error is \(error.localizedDescription)")
                            if let responseData = response.data, let errorResponseJSON = String(data: responseData, encoding: String.Encoding.utf8) {
                                var serverError = ServerError(JSONString: errorResponseJSON)
                                if serverError == nil {
                                    serverError = ServerError.defaultError
                                }
                                completionHandler(serverError, nil)
                            } else {
                                completionHandler(ServerError.defaultError, nil)
                            }
                        }
                    })
                } else {
                    completionHandler(ServerError.defaultError, nil)
                }
            } else {
                completionHandler(ServerError.noInternet, nil)
            }
        } else {
            completionHandler(ServerError.defaultError, nil)
        }
    }
    
    /*
     Requests a prepared shipment for a specified Track&Trace number
     API call: http://dev.modum.io/api/preparedshipments/tntNumber/<tntNumber>
     - @tntNumber: Track&Trace number of the shipment
     - @completionHandler: returns a boolean variable, indicating whether request was successful or not
     */
    func getPreparedShipment(tntNumber: String, completionHandler: @escaping (ServerError?, PreparedShipment?) -> Void) {
        if let reachability = reachability {
            if reachability.isReachable {
                if let authorizationHeader = authorizationHeader {
                    Alamofire.request(DEV_API_URL + "preparedshipments/tntnumber/\(tntNumber)", method: .get, encoding: JSONEncoding.default, headers: ["Authorization" : authorizationHeader]).validate().responseObject(completionHandler: {
                        (response: DataResponse<PreparedShipment>) -> Void in
                        
                        switch response.result {
                        case .success:
                            completionHandler(nil, response.result.value)
                        case .failure(let error):
                            log("Error is \(error.localizedDescription)")
                            if let responseData = response.data, let errorResponseJSON = String(data: responseData, encoding: String.Encoding.utf8) {
                                var serverError = ServerError(JSONString: errorResponseJSON)
                                if serverError == nil {
                                    serverError = ServerError.defaultError
                                }
                                completionHandler(serverError, nil)
                            } else {
                                completionHandler(ServerError.defaultError, nil)
                            }
                        }
                    })
                } else {
                    completionHandler(ServerError.defaultError, nil)
                }
            } else {
                completionHandler(ServerError.noInternet, nil)
            }
        } else {
            completionHandler(ServerError.defaultError, nil)
        }
    }
    
    /*
     Requests list of sensors IDs associated with given @tntNumber parameter
     API call: GET http://dev.modum.io/api/parcels/<tntNumber>
     - @completionHandler returns Error object if error occured and [Sensor] objects if it was returned
     */
    func getSensorIDArrayForParcel(tntNumber: String, completionHandler: @escaping (ServerError?, [Sensor]?) -> Void) {
        if let reachability = reachability {
            if reachability.isReachable {
                if let authorizationHeader = authorizationHeader {
                    Alamofire.request(DEV_API_URL + "parcels/\(tntNumber)", method: .get, encoding: JSONEncoding.default, headers: ["Authorization" : authorizationHeader]).validate().responseArray(completionHandler: {
                        (response: DataResponse<[Sensor]>) -> Void in
                        
                        switch response.result {
                        case .success:
                            completionHandler(nil, response.result.value)
                        case .failure(let error):
                            log("Error is \(error.localizedDescription)")
                            if let responseData = response.data, let errorResponseJSON = String(data: responseData, encoding: String.Encoding.utf8) {
                                var serverError = ServerError(JSONString: errorResponseJSON)
                                if serverError == nil {
                                    serverError = ServerError.defaultError
                                }
                                completionHandler(serverError, nil)
                            } else {
                                completionHandler(ServerError.defaultError, nil)
                            }
                        }
                    })
                } else {
                    completionHandler(ServerError.defaultError, nil)
                }
            } else {
                completionHandler(ServerError.noInternet, nil)
            }
        } else {
            completionHandler(ServerError.defaultError, nil)
        }
    }
    
    /*
     Uploads temperature measurements for a parcel given @tntNumber and @sensorID parameters
     API call: POST http://dev.modum.io/api/parcels/<tntNumber>/<sensorID>/temperatures
     - @completionHandler returns ServerError object if error occured and SmartContractStatus object if it was returned
     */
    func postTemperatureMeasurements(tntNumber: String, sensorID: String, measurements: TemperatureMeasurementsObject, completionHandler: @escaping (ServerError?, TemperatureMeasurementsObject?) -> Void) {
        if let authorizationHeader = authorizationHeader {
            let backgroundConfiguration = URLSessionConfiguration.background(withIdentifier: "modum.io.iosclient")
            let sessionManager = Alamofire.SessionManager(configuration: backgroundConfiguration)
            var dateComponents = DateComponents()
            dateComponents.day = 3
            let in3Days = Calendar.current.date(byAdding: dateComponents, to: Date())
            sessionManager.retrier = ModumRequestRetrier(endDate: in3Days!)
            sessionManager.request(DEV_API_URL + "parcels/\(tntNumber)/\(sensorID)/temperatures", method: .post, parameters: measurements.toJSON(), encoding: JSONEncoding.default, headers: ["Authorization" : authorizationHeader]).validate().responseObject(completionHandler: {
                (response: DataResponse<TemperatureMeasurementsObject>) -> Void in
                
                switch response.result {
                case .success:
                    completionHandler(nil, response.result.value)
                case .failure(let error):
                    log("Error is \(error.localizedDescription)")
                    if let responseData = response.data, let errorResponseJSON = String(data: responseData, encoding: String.Encoding.utf8) {
                        var serverError = ServerError(JSONString: errorResponseJSON)
                        if serverError == nil {
                            serverError = ServerError.defaultError
                        }
                        completionHandler(serverError, nil)
                    } else {
                        completionHandler(ServerError.defaultError, nil)
                    }
                }
            })
        } else {
            completionHandler(ServerError.defaultError, nil)
        }
    }

    /*
     Uploads created parcel to the server
     API call: POST http://dev.modum.io/api/v2/parcels/create
     - @completionHandler returns ServerError object if error occured
     */
    func createParcel(parcel: CreatedParcel, completionHandler: @escaping (ServerError?, Parcel?) -> Void) {
        if let reachability = reachability {
            if reachability.isReachable {
                if let authorizationHeader = authorizationHeader {
                    log("JSON parcel: \(parcel.toJSON())")
                    Alamofire.request(DEV_API_URL + "v2/parcels/create", method: .post, parameters: parcel.toJSON(), encoding: JSONEncoding.default, headers: ["Authorization" : authorizationHeader]).validate().responseObject(completionHandler: {
                        (response: DataResponse<Parcel>) -> Void in
                        
                        switch response.result {
                        case .success:
                            completionHandler(nil, response.result.value)
                        case .failure(let error):
                            log("Error is \(error.localizedDescription)")
                            if let responseData = response.data, let errorResponseJSON = String(data: responseData, encoding: String.Encoding.utf8) {
                                var serverError = ServerError(JSONString: errorResponseJSON)
                                if serverError == nil {
                                    serverError = ServerError.defaultError
                                }
                                completionHandler(serverError, nil)
                            } else {
                                completionHandler(ServerError.defaultError, nil)
                            }
                        }
                    })
                } else {
                    completionHandler(ServerError.defaultError, nil)
                }
            } else {
                completionHandler(ServerError.noInternet, nil)
            }
        } else {
            completionHandler(ServerError.defaultError, nil)
        }
    }
    
    /*
     Requests a temperature measurements smart contract status for a parcel given @tntNumber and @sensorID parameters
     API call: http://dev.modum.io/api/parcels/<tntNumber>/<sensorID>/temperatures/status
     - @completionHandler returns Error object if error occured and SmartContractStatus object if it was returned
     */
    func getCompanyDefaults(completionHandler: @escaping (ServerError?, CompanyDefaults?) -> Void) {
        if let reachability = reachability {
            if reachability.isReachable {
                if let authorizationHeader = authorizationHeader {
                    Alamofire.request(DEV_API_URL + "/v1/company/defaults", method: .get, parameters: nil, encoding: JSONEncoding.default, headers: ["Authorization" : authorizationHeader]).validate().responseObject(completionHandler: {
                        (response: DataResponse<CompanyDefaults>) -> Void in
                        
                        switch response.result {
                        case .success:
                            completionHandler(nil, response.result.value)
                        case .failure(let error):
                            log("Error is \(error.localizedDescription)")
                            if let responseData = response.data, let errorResponseJSON = String(data: responseData, encoding: String.Encoding.utf8) {
                                var serverError = ServerError(JSONString: errorResponseJSON)
                                if serverError == nil {
                                    serverError = ServerError.defaultError
                                }
                                completionHandler(serverError, nil)
                            } else {
                                completionHandler(ServerError.defaultError, nil)
                            }
                        }
                    })
                } else {
                    completionHandler(ServerError.defaultError, nil)
                }
            } else {
                completionHandler(ServerError.noInternet, nil)
            }
        } else {
            completionHandler(ServerError.defaultError, nil)
        }
    }
    
}
