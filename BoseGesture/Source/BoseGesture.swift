//
//  BoseGesture.swift
//  BoseGesture
//
//  Created by Jorge Castellanos on 6/3/19.
//  Copyright © 2019 Bose Corporation. All rights reserved.
//

import Foundation
import os.log

/**
 Top-level interface to the BoseGesture library. Note that you must call `BoseGesture.configure(withKey:)` with a valid API key before using the `BoseGesture.shared` singleton instance.
 */
public class BoseGesture {

    /// The singleton `BoseGesture` instance.
    private static let singleton = BoseGesture()

    /// The BoseGesture bundle, used to access any resources inside the Gesture Library
    static var bundle: Bundle {
        return Bundle(for: BoseGesture.self)
    }

    /// The gesture recognizer. This object is in charge of predicting gestures usin sensor data as input.
    public let recognizer: BoseGestureRecognizer = BoseMLGestureRecognizer()
}

// MARK: - Static interface

/// Static interface
extension BoseGesture {

    /**
     Configures the BoseGesture library. Note this function can only be called once. Subsequent calls will result in a fatal error.

     - parameter analyticsOn: Boolean flag determining whether to turn Bose analytics tracking on. Disabled by default. 
          Enabling analytics helps developers improve their apps by allowing Bose to share data and usage statistics about your apps.  
     */
    public static func configure() {

    }

    /// The shared singleton `BoseGesture` instance. Note that the `BoseGesture.configure(withKey:)` method must be called first in order to use the `BoseGesture.shared` instance.
    public static var shared: BoseGesture {
        return singleton
    }

    /// The release version of the BoseGesture framework. This corresponds to the CFBundleShortVersionString key in the framework's `Info.plist`.
    public static var releaseVersion: String? {
        return bundle.infoDictionary?["CFBundleShortVersionString"] as? String
    }

    /// The build number of the BoseGesture framework. This corresponds to the CFBundleVersion key in the framework's `Info.plist`.
    public static var buildNumber: String? {
        return bundle.infoDictionary?["CFBundleVersion"] as? String
    }

    /// The formatted version of the BoseGesture framework, combining the release version and build number.
    public static var formattedVersion: String {
        return "v\(releaseVersion ?? "?") (\(buildNumber ?? "?"))"
    }
}
