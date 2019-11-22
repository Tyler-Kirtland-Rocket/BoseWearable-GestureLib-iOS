# Usage

This document describes how to use the Bose Gesture Library in your app.

- [Client App Requirements](#client-app-requirements)
- [Configuring and Initializing the Library](#configuring-and-initializing-the-library)
- [Recognizing Gestures](#recognizing-gestures)

## Client App Requirements

The Gesture Library detects gestures performed while wearing a Bose AR device. In order to connect to the device and communicate with it, the App must first link against the Bose Wearable SDK.


## Configuring and Initializing the Library

Before using the Bose Wearable library, you will need to call `BoseWearable.configure(_:)`. We recommend doing so in your app delegate. For example:

```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

    // ...

    // Configure the BoseWearable SDK.
    BoseWearable.configure()

    // Configure and authenticate the BoseGesture library using our own API key.
    BoseGesture.configure(analyticsOn: Bool = false) { result in
        switch result {
        case .success:
            print("BoseGesture configured")

        case .failure(let error):
            print("BoseGesture failed: \(error.localizedDescription)")
        }
    }
    // ...

    return true
}
```

The `BoseGesture.configure(analyticsOn:)` method takes a boolean flag toggling analytics tracking as its only parameter (by default, analytics are not enabled). See the documentation for more details.

## Recognizing Gestures

### Feeding Sensor Data

The `BoseGesture` library uses the Bose AR device sensor data to detect gestures, so we need to feed the sensor data from the `BoseWearable SDK` into the `BoseGesture` library. Specifically, the Accelerometer and Gyroscope sensors. You should enable the sensors at a 10 MS sample period. To learn more on configuring and activating these sensors please look at the BoseWearable SDK documentation. Once the sensors are enabled, just pass the sensor data into the Gesture Recognizer:

```swift
    // Wearable SDK accelerometer callback
    func receivedAccelerometer(vector: Vector, accuracy: VectorAccuracy, timestamp: SensorTimestamp) {

        // Pass the accelerometer sensor data into the BoseGesture library.
        BoseGesture.shared.recognizer.appendAccelerometer(data: vector, accuracy: accuracy, timestamp: timestamp)
    }

    // Wearable SDK gyroscope callback
    func receivedGyroscope(vector: Vector, accuracy: VectorAccuracy, timestamp: SensorTimestamp)  {

        // Pass the gyroscope sensor data into the BoseGesture library.
        BoseGesture.shared.recognizer.appendGyroscope(data: vector, accuracy: accuracy, timestamp: timestamp)
    }
```

### Recognizing Gestures

Once the BoseWearable SDK is configured, both the accelerometer and gyroscope sensors are enabled and delegated to the BoseGesture library as shown above, the final step is to call `startDetectingGestures()` on the gesture recognizer as follows:

```swift
	// Start listening for gestures.
	BoseGesture.shared.recognizer.startDetectingGestures() { [weak self] gesture, confidence in
	    switch gesture {
        case .lookDown:
            print("Looking down")
        case .headNod:
            print("Yes!")
        default:
            print("Some other gesture")
        }
	}
```
The `confidence` parameter will indicate how likely it is that the given gesture is actually that gesture.
