//
//  Date+Extension.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 25.01.17.
//  Copyright © 2017 Modum. All rights reserved.
//

import Foundation

extension Date {
    
    static let iso8601Formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
        return formatter
    }()
    
    var iso8601: String {
        return Date.iso8601Formatter.string(from: self)
    }
    
    func components() -> DateComponents {
        let calendar = Calendar.current
        return calendar.dateComponents(Set<Calendar.Component>([.year, .month, .weekOfMonth, .weekday, .day]), from:self)
    }
    
    /*
     Returns true if @otherDate represents the same day
     Else, returns false
     */
    func isSameDay(AsOtherDate otherDate: Date) -> Bool {
        let thisDateComponents = components()
        let otherDayComponents = otherDate.components()
        return thisDateComponents.year == otherDayComponents.year && thisDateComponents.month == otherDayComponents.month && thisDateComponents.day == otherDayComponents.day
    }
    
    /*
     Returns true iff the date's day component is same as today's date component
     Else, returns false
     */
    func isToday() -> Bool {
        return isSameDay(AsOtherDate: Date())
    }
    
    /* Produces String description of NSDate with a given NSDateFormatterStyle */
    func toString(WithDateStyle dateStyle: DateFormatter.Style?, WithTimeStyle timeStyle: DateFormatter.Style?) -> String {
        
        let dateFormatter = DateFormatter()
        
        var dateAsString: String = ""
        
        if let dateStyle = dateStyle {
            if isToday() {
                dateAsString += "Today "
            } else {
                dateFormatter.dateStyle = dateStyle
            }
        }
        if let timeStyle = timeStyle {
            dateFormatter.timeStyle = timeStyle
        }
        dateAsString += dateFormatter.string(from: self)
        return dateAsString
    }
    
}
