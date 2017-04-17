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
        if let timeInterval = timeInterval {
            completion(true, timeInterval)
        } else {
            completion(true, DEFAULT_TIME_INTERVAL)
        }
    }
    
}
