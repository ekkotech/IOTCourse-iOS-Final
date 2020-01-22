//
//  CoreBluetooth.swift
//  IOTCourse4
//
//  Created by Andrew Coad on 29/05/2019.
//  Copyright © 2019 IOTCourse4. All rights reserved.
//

import Foundation
import UIKit
import CoreBluetooth

//
// Protection against a mal-formed UUID string
// CBUUID(string: ) will crash if string does not conform to 8-4-4-4-12 structure or has alpha not
// in the range a-fA-F
//
extension CBUUID {
    convenience init?(uuidString: String) {
        do {
            let regex = try NSRegularExpression(pattern: "(\\b([0-9a-f]{4}|[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})\\b)", options: .caseInsensitive)
            let numberOfMatches:Int = regex.numberOfMatches(in: uuidString, options: [], range: NSMakeRange(0, uuidString.count))
            if numberOfMatches == 1 { self.init(string: uuidString) }
            else { return nil }
        }
        catch { return nil }
    }
}

extension CBUUID {
    convenience init(baseUuid: String, shortUuid: String) {
        // Length of base uuid should be 36; 32 uuid characters plus 4 "-"
        // Length of short uuid should be 4
        // Lengths of strings checked here - invalid characters will cause fail in call to self.init()
        if baseUuid.count != 36 && shortUuid.count != 4 {
            assertionFailure()
        }
        
        var newValue = baseUuid
        let start = newValue.index(newValue.startIndex, offsetBy: 4)
        let end = newValue.index(start, offsetBy: 4)
        newValue.replaceSubrange(start..<end, with: shortUuid)
        self.init(string: newValue)
    }
}

//
// Human readable CBCentralManager state descriptions
//
extension CBManagerState /*: CustomStringConvertible*/ {
    public var description: String {
        switch self {
        case .poweredOn:
            return "poweredOn"
        case .poweredOff:
            return "poweredOff"
        case .resetting:
            return "resetting"
        case .unauthorized:
            return "unauthorised"
        case .unknown:
            return "unknown"
        case .unsupported:
            return "unsupported"
        @unknown default:
            return "undefined"
        }
    }
    
}

