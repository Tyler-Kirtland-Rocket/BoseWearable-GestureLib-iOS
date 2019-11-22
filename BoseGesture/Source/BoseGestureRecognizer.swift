//
//  BoseGestureRecognizer.swift
//  BoseGesture
//
//  Created by Jorge Castellanos on 6/9/19.
//  Copyright © 2019 Bose Corporation. All rights reserved.
//

import BoseWearable
import Foundation

/**
 Base Gesture recognizer class, common to specific recognizer implementations.
 */
public class BoseGestureRecognizer {

    /// Set of gestures that will be detected by the library. It defaults to all available gestures.
    public var enabledGestures = Set(BoseGestureType.all)

    /// This will get called with a gesture —if any is detected—.
    public var gestureDataCallback: ((BoseGestureType, Int) -> Void)?

    /// Timer to timeout the gesture recognition window
    private var detectionTimer: Timer?

    /**
     Starts recognizing gestures. Optionally it can automatically stop recognizing after a given time interval.

     - parameter timeout: a time interval in seconds after which gesture recognition will stop.
     - parameter gestureCallback: a function that will get called when a gesture has been detected.
     */
    public func startDetectingGestures(timeout: TimeInterval? = nil, gestureCallback: @escaping ((BoseGestureType, Int) -> Void)) {
        gestureDataCallback = gestureCallback

        if let timeInterval = timeout {
            detectionTimer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false) { [weak self] _ in
                self?.stopDetectingGestures()
            }
        }
    }

    /// It stops detecting gestures and invalidates the previously set timer and callback
    public func stopDetectingGestures() {
        detectionTimer?.invalidate()
        detectionTimer = nil

        gestureDataCallback = nil
    }

    /// Call this function to feed accelerometer data into the gesture recognizer.
    /// It shares the same signature as the Wearable SDK's sensor data callbacks, so it's just a matter of adding this on the accelerometer callback from the SDK.
    public func appendAccelerometer(data: Vector, accuracy: VectorAccuracy, timestamp: SensorTimestamp) { }

    /// Call this function to feed gyroscope data into the gesture recognizer.
    /// It shares the same signature as the Wearable SDK's sensor data callbacks, so it's just a matter of adding this on the gyroscope callback from the SDK.
    public func appendGyroscope(data: Vector, accuracy: VectorAccuracy, timestamp: SensorTimestamp) { }

    /// Clear any history of or pertaining to sensor data
    public func flush() { }
}
