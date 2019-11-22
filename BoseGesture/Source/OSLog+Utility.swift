//
//  OSLog+Utility.swift
//  OSLog+Utility
//
//  Created by David Schmitz on 4/5/19.
//  Copyright © 2019 Bose Corporation. All rights reserved.
//

import Foundation
import os.log

extension OSLog {

    /// The log subsystem for BoseWearable.
    private static let subsystem = "com.bose.ar.BoseGesture"

    /// Category for configuration log messages.
    static let general = OSLog(subsystem: subsystem, category: "general")

    /// Category for configuration log messages.
    static let configure = OSLog(subsystem: subsystem, category: "configure")

    /// Category for analytics log messages.
    static let analytics = OSLog(subsystem: subsystem, category: "analytics")

    static func debug(_ log: OSLog, message: String) {
        os_log("%@", log: log, type: .debug, message)
    }

    static func info(_ log: OSLog, message: String) {
        os_log("%@", log: log, type: .info, message)
    }

    static func error(_ log: OSLog, message: String) {
        os_log("%@", log: log, type: .error, message)
    }
}
