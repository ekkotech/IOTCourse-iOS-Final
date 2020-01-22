//
//  Log.swift
//  IOTCourse3
//
//  Created by Andrew Coad on 24/10/2019.
//  Copyright © 2019 Andrew Coad. All rights reserved.
//

import Foundation
import os

private let subsystem = Bundle.main.bundleIdentifier ?? "Unamed"

/**
 Subsystem and categories are provided to facilitate seaching and filtering the log content.  Susbsytem will always be the bundle identifier; categories can be added as required
 */
struct Log {
    static let ble = OSLog(subsystem: subsystem, category: "bluetooth")
    static let model = OSLog(subsystem: subsystem, category: "model")
    static let ui = OSLog(subsystem: subsystem, category: "ui")
}
