//
//  UNUserNotificationCenter+Extension.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 21.04.17.
//  Copyright © 2017 Modum. All rights reserved.
//

import UserNotifications

extension UNUserNotificationCenter {
    
    func removeNotification(identifier: String) {
        removeDeliveredNotifications(withIdentifiers: [identifier])
        removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
}
