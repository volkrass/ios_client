//
//  ModumRequestRetrier.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 07.04.17.
//  Copyright © 2017 Modum. All rights reserved.
//

import Alamofire

class ModumRequestRetrier : RequestRetrier {
    
    // MARK: Properties
    
    /* how often should request be retried */
    fileprivate let timeInterval: TimeInterval?
    
    // MARK: Constants
    
    fileprivate let DEFAULT_TIME_INTERVAL: TimeInterval = 10
    
    init(timeInterval: TimeInterval? = nil) {
        self.timeInterval = timeInterval
    }
    
    // MARK: RequestRetrier
    
    func should(_ manager: SessionManager, retry request: Request, with error: Error, completion: @escaping RequestRetryCompletion) {
        if let response = request.response, let url = request.request?.url {
            /* in case of v2/parcels/create call, 400 error designate that the parcel .... and 409 error designate that the parcel ... */
            if url.absoluteString == ServerManager.DEV_API_URL + "v2/parcels/create", response.statusCode != 400, response.statusCode != 409 {
                if let timeInterval = timeInterval {
                    completion(true, timeInterval)
                } else {
                    completion(true, DEFAULT_TIME_INTERVAL)
                }
            } else if url.absoluteString.hasPrefix(ServerManager.DEV_API_URL + "parcels/") && url.absoluteString.hasSuffix("/temperatures") {
                /* in case /parcels/\(tntNumber)/\(sensorID)/temperatures call, */
                if let timeInterval = timeInterval {
                    completion(true, timeInterval)
                } else {
                    completion(true, DEFAULT_TIME_INTERVAL)
                }
            } else {
                completion(false, DEFAULT_TIME_INTERVAL)
            }
        } else {
            completion(false, DEFAULT_TIME_INTERVAL)
        }
    }
    
}
