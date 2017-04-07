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
    
    /* determines until which date request should be retried */
    fileprivate let endDate: Date
    
    /* how often should request be retried */
    fileprivate let timeInterval: TimeInterval?
    
    // MARK: Constants
    
    fileprivate let DEFAULT_TIME_INTERVAL: TimeInterval = 10
    
    init(endDate: Date, timeInterval: TimeInterval? = nil) {
        self.endDate = endDate
        self.timeInterval = timeInterval
    }
    
    // MARK: RequestRetrier
    
    func should(_ manager: SessionManager, retry request: Request, with error: Error, completion: @escaping RequestRetryCompletion) {
        let now = Date()
        if now < endDate {
            if let timeInterval = timeInterval {
                completion(true, timeInterval)
            } else {
                completion(true, DEFAULT_TIME_INTERVAL)
            }
        }
    }
    
}
