//
//  UNUserNotificationCenter+Extension.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 21.04.17.
//  Copyright © 2017 Modum. All rights reserved.
//

import UserNotifications

extension UNUserNotificationCenter {
    
    /* convinience method to remove both pending and delivered notifications from notification center */
    func removeNotification(identifier: String) {
        removeDeliveredNotifications(withIdentifiers: [identifier])
        removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
}
