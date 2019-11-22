//
//  BoseGestureType.swift
//  BoseGesture
//
//  Created by Jorge Castellanos on 6/6/19.
//  Copyright © 2019 Bose Corporation. All rights reserved.
//

import Foundation

/// Identifies a gesture recognized by a wearable device.
public enum BoseGestureType: UInt8, Codable {

    /// Non-event - no gesture detected
    case nonEvent

    /// Look up gesture.
    case lookUp

    /// Look down gesture.
    case lookDown

    /// Look left gesture.
    case lookLeft

    /// Look right gesture.
    case lookRight

    /// Tilt left gesture.
    case tiltLeft

    /// Tilt right gesture
    case tiltRight

    /// Head nod gesture
    case headNod

    /// Head shake gesture
    case headShake

    /// The set of gestures supported by the SDK. See `WearableDeviceInformation.availableGestures` and `GestureInformation.availableGestures` for the set of gestures supported by a given wearable device.
    public static var all: [BoseGestureType] = [
        .lookUp,
        .lookDown,
        .lookLeft,
        .lookRight,
        .tiltLeft,
        .tiltRight,
        .headNod,
        .headShake
    ]

    public static func from(_ label: String) -> BoseGestureType {
        let gestureType: BoseGestureType
        switch label {
        case "look_up":
            gestureType = .lookUp
        case "look_down":
            gestureType = .lookDown
        case "look_left":
            gestureType = .lookLeft
        case "look_right":
            gestureType = .lookRight
        case "tilt_left":
            gestureType = .tiltLeft
        case "tilt_right":
            gestureType = .tiltRight
        case "head_nod":
            gestureType = .headNod
        case "head_shake":
            gestureType = .headShake
        default:
            gestureType = .nonEvent
        }
        return gestureType
    }

    var label: String {
        switch self {
        case .lookUp:
            return "look_up"

        case .lookDown:
            return "look_down"

        case .lookLeft:
            return "look_left"

        case .lookRight:
            return "look_right"

        case .tiltLeft:
            return "tilt_left"

        case .tiltRight:
            return "tilt_right"

        case .headNod:
            return "head_nod"

        case .headShake:
            return "head_shake"

        case .nonEvent:
            return "non_event"

        }
    }
}
