//
//  DataCollectionViewController.swift
//  Copyright © 2019 Bose Corporation. All rights reserved.
//  Paul Calnan, Hiren, Aayush Sinha

import BoseWearable
import BoseGesture
import UIKit
import MessageUI

class DataCollectionViewController: UIViewController {

    private var activityIndicator: ActivityIndicator?

    @IBOutlet weak var gestureLabel: UILabel!
    @IBOutlet weak var confidenceLabel: UILabel!

    /// Set by the showing/presenting code.
    var session: WearableDeviceSession? {
        didSet {
            // Register this view controller as the session delegate.
            session?.delegate = self as WearableDeviceSessionDelegate

            // Set the title to the device's name.
            title = session?.device?.name

            // Start listening for gestures.
            BoseGesture.shared.recognizer.startDetectingGestures() { [weak self] gesture, confidence in
                self?.gestureLabel.text = String(describing: gesture)
                self?.confidenceLabel.text = String(confidence)
                self?.gestureLabel.fadeIn() { _ in
                    self?.gestureLabel.fadeOut()
                }
                self?.confidenceLabel.fadeIn() { _ in
                    self?.confidenceLabel.fadeOut()
                }
            }

            // Listen for wearable device events.
            listenForWearableDeviceEvents()

            // Listen for sensor data.
            listenForSensors()
        }
    }

    // We create the SensorDispatch without any reference to a session or a device.
    // We provide a queue on which the sensor data events are dispatched on.
    private let sensorDispatch = SensorDispatch(queue: .main)
    
    /// Retained for the lifetime of this object. When deallocated, deregisters
    /// this object as a WearableDeviceEvent listener.
    private var token: ListenerToken?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Default the labels to "---"
        gestureLabel.text = "––"
        confidenceLabel.text = "––"

        sensorDispatch.handler = self as SensorDispatchHandler
        
        // Block this view controller's UI before showing the modal search.
        activityIndicator = ActivityIndicator.add(to: navigationController?.view)

        // Perform the device search and connect to the selected device. This
        // may present a view controller on a new UIWindow.
        BoseWearable.shared.startConnection(mode: .connectToLast(timeout: 5)) { result in
            switch result {
            case .success(let session):
                // A device was selected, a session was created and opened.
                self.session = session

            case .failure(let error):
                // An error occurred when searching for or connecting to a
                // device. Present an alert showing the error.
                self.show(error)

            case .cancelled:
                // The user cancelled the search operation.
                break
            }

            // Unblock the UI
            self.activityIndicator?.removeFromSuperview()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        

    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Disable all sensors when dismissing. Since we retain the session
        // and will be deallocated after this, the session will be deallocated
        // and the communications channel closed.
        stopListeningForSensors()

        // Stop gesture recognition.
        BoseGesture.shared.recognizer.stopDetectingGestures()
    }

    // Error handler function called at various points in this class.  If an error
    // occurred, show it in an alert. When the alert is dismissed, this function
    // dismisses this view controller by popping to the root view controller (we are
    // assumed to be on a navigation stack).
    private func dismiss(dueTo error: Error?, isClosing: Bool = false) {
        // Common dismiss handler passed to show()/showAlert().
        let popToRoot = { [weak self] in
            DispatchQueue.main.async {
                self?.navigationController?.popToRootViewController(animated: true)
            }
        }
        
        // If the connection did close and it was not due to an error, just show
        // an appropriate message.
        if isClosing && error == nil {
            navigationController?.showAlert(title: "Disconnected", message: "The connection was closed", dismissHandler: popToRoot)
        }
            // Show an error alert.
        else {
            navigationController?.show(error, dismissHandler: popToRoot)
        }
    }
    
    private func listenForWearableDeviceEvents() {
        // Listen for incoming wearable device events. Retain the ListenerToken.
        // When the ListenerToken is deallocated, this object is automatically
        // removed as an event listener.
        token = session?.device?.addEventListener(queue: .main) { [weak self] event in
            self?.wearableDeviceEvent(event)
        }
    }
    
    private func wearableDeviceEvent(_ event: WearableDeviceEvent) {
        // We are only interested in the event that the sensor configuration could
        // not be updated. In this case, show the error to the user. Otherwise,
        // ignore the event.
        guard case .didFailToWriteSensorConfiguration(let error) = event else {
            return
        }
        show(error)
    }
    
    private func listenForSensors() {
        // Configure sensors at 50 Hz (a 20 ms sample period)
        session?.device?.configureSensors { config in
            
            // Here, config is the current sensor config. We begin by turning off
            // all sensors, allowing us to start with a "clean slate."
            config.disableAll()
            
            // Enable the rotation and accelerometer sensors
            config.enable(sensor: .gyroscope, at: ._10ms)
            config.enable(sensor: .accelerometer, at: ._10ms)
        }
    }
    
    private func stopListeningForSensors() {
        // Disable all sensors.
        session?.device?.configureSensors { config in
            config.disableAll()
        }
    }

}

// MARK: - SensorDispatchHandler

// Note, we only have to implement the SensorDispatchHandler functions for the
// sensors we are interested in. These functions are called on the main queue
// as that is the queue provided to the SensorDispatch initializer.

extension DataCollectionViewController: SensorDispatchHandler {

    // Wearable SDK accelerometer callback
    func receivedAccelerometer(vector: Vector, accuracy: VectorAccuracy, timestamp: SensorTimestamp) {

        // Pass our accelerometer sensor data into the BoseGesture library.
        BoseGesture.shared.recognizer.appendAccelerometer(data: vector, accuracy: accuracy, timestamp: timestamp)
    }

    // Wearable SDK gyroscope callback
    func receivedGyroscope(vector: Vector, accuracy: VectorAccuracy, timestamp: SensorTimestamp)  {

        // Pass our gyroscope sensor data into the BoseGesture library.
        BoseGesture.shared.recognizer.appendGyroscope(data: vector, accuracy: accuracy, timestamp: timestamp)
    }

}

// MARK: - WearableDeviceSessionDelegate

//This function looks for sensors in the device

extension DataCollectionViewController: WearableDeviceSessionDelegate {
    func sessionDidOpen(_ session: WearableDeviceSession) {
        // The session opened successfully.
        
    }
    
    func session(_ session: WearableDeviceSession, didFailToOpenWithError error: Error) {
        // The session failed to open due to an error.
        dismiss(dueTo: error)
    }
    
    func session(_ session: WearableDeviceSession, didCloseWithError error: Error) {
        // The session was closed, possibly due to an error.
        dismiss(dueTo: error, isClosing: true)
    }

    func sessionDidClose(_ session: WearableDeviceSession) {
        dismiss(dueTo: nil, isClosing: true)
    }
}
    
