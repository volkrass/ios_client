//
//  Logging.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 25.10.16.
//  Copyright © 2016 Modum. All rights reserved.
//

import Foundation
import UIKit

/* COLORS */

let MODUM_LIGHT_BLUE: UIColor = UIColor(red: 48.0/255.0, green: 170.0/255.0, blue: 223.0/255.0, alpha: 1.0)
let MODUM_DARK_BLUE: UIColor = UIColor(red: 18.0/255.0, green: 85.0/255.0, blue: 122.0/255.0, alpha: 1.0)
let MODUM_LIGHT_GRAY: UIColor = UIColor(red: 239.0/255.0, green: 239.0/255.0, blue: 244.0/255.0, alpha: 1.0)

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

/*
 Returns true if given String is 'valid' MAC address string
 Otherwise, returns false
 Note: 'valid' MAC address strings are considered if MAC address is given without any separators
 */
func isValidMacAddress(_ macAddressStr: String) -> Bool {
    guard macAddressStr.characters.count == 12 else {
        return false
    }
    return macAddressStr.isValidHexString()
}

/* Converts given value to byte array */
func toByteArray<T>(_ value: T) -> [UInt8] {
    var value = value
    return withUnsafeBytes(of: &value) { Array($0) }
}
