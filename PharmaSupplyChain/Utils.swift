//
//  Logging.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 25.10.16.
//  Copyright © 2016 Modum. All rights reserved.
//

import Foundation
import UIKit

/* UI Constants */

/* Device screen size for use in ViewControllers */
enum ScreenSize : Int {
    /* iPhone 5, iPhone 5S, iPhone SE */
    case small = 0
    /* iPhone 6, iPhone 6s */
    case large = 1
    /* iPhone 6 Plus, iPhone 6s Plus, iPhone 7, iPhone 7 Plus */
    case veryLarge = 2
    /* undetermined screen size, fall back to default settings */
    case `default` = 3
}

/* COLORS */

let MODUM_LIGHT_BLUE: UIColor = UIColor(red: 48.0/255.0, green: 170.0/255.0, blue: 223.0/255.0, alpha: 1.0)
let MODUM_DARK_BLUE: UIColor = UIColor(red: 18.0/255.0, green: 85.0/255.0, blue: 122.0/255.0, alpha: 1.0)
let MODUM_LIGHT_GRAY: UIColor = UIColor(red: 239.0/255.0, green: 239.0/255.0, blue: 244.0/255.0, alpha: 1.0)
let STATUS_ORANGE: UIColor = UIColor(red: 255.0/255.0, green: 128.0/255.0, blue: 0.0, alpha: 0.73)
let STATUS_RED: UIColor = UIColor(red: 255.0/255.0, green: 50.0/255.0, blue: 0.0, alpha: 0.73)
let STATUS_GREEN: UIColor = UIColor(red: 12.0/255.0, green: 199.0/255.0, blue: 17.0/255.0, alpha: 0.73)
let TEMPERATURE_LIGHT_RED: UIColor = UIColor(red: 255.0/255.0, green: 50.0/255.0, blue: 0.0, alpha: 1.0)
let TEMPERATURE_LIGHT_BLUE: UIColor = UIColor(red: 88.0/255.0, green: 208.0/255.0, blue: 255.0/255.0, alpha: 0.8)
let ROSE_COLOR: UIColor = UIColor(red: 242.0/255.0, green: 127.0/255.0, blue: 97.0/255.0, alpha: 1.0)
let LIGHT_BLUE_COLOR: UIColor = UIColor(red: 165.0/255.0, green: 209.0/255.0, blue: 204.0/255.0, alpha: 1.0)
let IOS7_BLUE_COLOR: UIColor = UIColor(red: 0.0, green: 122.0/255.0, blue: 1.0, alpha: 1.0)

/*
 The function to be used for logging throughout the project
 All calls to "print" should be replaced with "log"
 */
func log(_ message: String, function: String = #function, file: String = #file, line: Int = #line) {
    #if DEBUG
        let url = NSURL(fileURLWithPath: file)
        guard let filename = url.deletingPathExtension?.lastPathComponent else {
            fatalError("Utils.log: failed to retrieve lastPathComponent")
        }
        print("\(message) [\(filename).\(function):\(line)]")
    #endif
}

/* Returns an array containing unique values which conform to Hashable */
func uniq<S: Sequence, E: Hashable>(_ source: S) -> [E] where E == S.Iterator.Element {
    var seen = [E: Bool]()
    return source.filter { seen.updateValue(true, forKey: $0) == nil }
}

/* Returns device screen size */
func getDeviceScreenSize() -> ScreenSize {
    let screenHeight = UIScreen.main.bounds.height
    if screenHeight <= 568 {
        return ScreenSize.small
    } else if screenHeight > 568 && screenHeight <= 667 {
        return ScreenSize.large
    } else if screenHeight > 667 && screenHeight <= 736 {
        return ScreenSize.veryLarge
    } else {
        return ScreenSize.default
    }
}

/*
 Returns true if given String is 'valid' MAC address string
 Otherwise, returns false
 Note: 'valid' MAC address strings are considered if MAC address is given without any separators
 */
func isValidMacAddress(_ macAddressStr: String) -> Bool {
    let macString = macAddressStr.removeNonHexSymbols()
    guard macString.characters.count == 12 else {
        return false
    }
    return macString.isValidHexString()
}

/* Converts given value to byte array */
func toByteArray<T>(_ value: T) -> [UInt8] {
    var value = value
    return withUnsafeBytes(of: &value) { Array($0) }
}
