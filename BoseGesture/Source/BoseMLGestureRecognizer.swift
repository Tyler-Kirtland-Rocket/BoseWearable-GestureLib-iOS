//
//  BoseMLGestureRecognizer.swift
//  BoseGesture
//
//  Created by Jorge Castellanos on 6/10/19.
//  Copyright © 2019 Bose Corporation. All rights reserved.
//

import BoseWearable
import CoreML
import Foundation

internal class BoseMLGestureRecognizer: BoseGestureRecognizer {

    private struct Constants {
        /// The total number of sensor samples (old + new) to be buffered up before invoking model inferencing
        static let samplesPerSensorDim = 98

        /// The number of new samples needed before invoking model inferencing
        static let accelSampleHopsPerInference = 10
        static let gyroSampleHopsPerInference = 10

        /// Sample period model was trained at. We will match the sample period of the incoming data to this by interpolating or dropping samples
        static let modelSamplePeriodMs = 10

        /// Ordering of sensor dimensions the model is expecting
        static let sensorDimOrdering = ["gyro_x", "gyro_y", "gyro_z", "accel_x", "accel_y", "accel_z"]

        /// Normalization values for each sensor dimension
        static let sensorMaxValueForNormalization = [1.0, 1.0, 1.0, 1.0, 1.0, 1.0]
        static let sensorMinValueForNormalization = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]

        /// Buffer historical predictions to smooth out fast changes in prediction reported to the user
        static let predHistoryLength: Int = 6

        /// Smoothing constant applied to prediction probabilities to reduce fast changes in confidence metric
        static let smoothingConstant = 0.9

        /// Min number of times a gesture must be present in history to be reported to callback
        static let minOccurenecesForReporting = 2

        /// Max number of times a gestures must be detected before being supressed. This is a workaround to make
        /// the user experience similar for all gestures, by only triggering transiently when the user is
        /// performing the gesture and not triggering all the time (for ex. when the user holds their head in a fixed up/down
        /// or tilted position.
        static let maxOccurencesForSuppressing = 6

        /// Threshold for reporting detected gesture to client
        static let minConfidenceThreshold = 80
    }

    /// Set MLPredictionOptions based on cpuMode
    private var predictionOptions: MLPredictionOptions {
        let options = MLPredictionOptions()
        options.usesCPUOnly = cpuMode
        return options
    }

    /// Buffer for storing accel and gyro data
    private var accelDataBuffer = SensorData(bufferLength: Constants.samplesPerSensorDim, dataType: .vector3d)
    private var gyroDataBuffer = SensorData(bufferLength: Constants.samplesPerSensorDim, dataType: .vector3d)

    /// Aggregate buffer for holding data before it is fed to the model
    private var aggregatedDataBuffer = try? MLMultiArray(shape: [NSNumber(value: Constants.samplesPerSensorDim * Constants.sensorDimOrdering.count)], dataType: MLMultiArrayDataType.double)

    /// Instantiate ML model
    private var gestureRecognitionModel = BoseMLGestureModel()

    /// Buffer for storing prediction and associated confidence histories
    private var predictionHistory: [BoseGestureType] = []
    private var confidenceHistory: [Double] = []

    /// Dictionary which holds latest smoothed confidences for each gesture
    private var smoothedConfidence: [BoseGestureType: Double] = [:]

    /// Store the last gesture which was detected and how many times it was detected
    private var lastDetectedGesture = BoseGestureType.nonEvent
    private var numTimesGestureDetected = 0

    /// Store the last gesture which was reported and how many times it was reported
    private var lastGestureReported = BoseGestureType.nonEvent
    private var numTimesGestureReported = 0

    /// Initialization function
    override init() {
        super.init()
        setup()
    }

    /// Append accelerometer data. Invoke model inferencing if sufficient numbers of new samples have been added.
    override public func appendAccelerometer(data: Vector, accuracy: VectorAccuracy, timestamp: SensorTimestamp) {
        // Add the data to our buffer.
        accelDataBuffer.appendData(timeStamp: timestamp, vector: data, modelSamplePeriodMs: Constants.modelSamplePeriodMs)
        predictActivity()
    }

    /// Append gyroscope data. Invoke model inferencing if sufficient numbers of new samples have been added.
    override public func appendGyroscope(data: Vector, accuracy: VectorAccuracy, timestamp: SensorTimestamp) {
        // Add the data to our buffer.
        gyroDataBuffer.appendData(timeStamp: timestamp, vector: data, modelSamplePeriodMs: Constants.modelSamplePeriodMs)
        predictActivity()
    }

    /// Clear any history of sensor data
    override public func flush() {
        accelDataBuffer.flushData()
        gyroDataBuffer.flushData()
        reset()
        setup()
    }

    /// Reset initial values
    private func reset() {
        predictionHistory = []
        confidenceHistory = []
        smoothedConfidence = [BoseGestureType: Double]()
        lastDetectedGesture = BoseGestureType.nonEvent
        numTimesGestureDetected = 0
        lastGestureReported = BoseGestureType.nonEvent
        numTimesGestureReported = 0
    }

    /// Setup buffer of nonEvents to set the state of the gesture recognizer
    private func setup() {
        for _ in 0..<Constants.predHistoryLength {
            predictionHistory.append(.nonEvent)
            confidenceHistory.append(100.0)
        }
        for gesture in BoseGestureType.all {
            smoothedConfidence[gesture] = 0
        }
        smoothedConfidence[.nonEvent] = 100
    }

    /// Compute predicted gesture and associated confidence
    private func predictActivity() {
        // Only run the predictor once we have enough sensor data.
        if accelDataBuffer.getNewDataCount() >= Constants.accelSampleHopsPerInference,
            gyroDataBuffer.getNewDataCount() >= Constants.gyroSampleHopsPerInference {
            var predictedGesture: BoseGestureType = .nonEvent
            var predictedConfidence: Int = 0
            aggregateData()
            guard let dataBuffer = aggregatedDataBuffer else {
                return
            }
            if let gestureResult = try? gestureRecognitionModel.prediction(input: BoseMLGestureModelInput(IMU_Sensor_Bose_Frames: dataBuffer), options: predictionOptions) {
                (predictedGesture, predictedConfidence) = postProcessPrediction(gestureResult: gestureResult)
            }
            resetSensorsNewDataCount()
            if predictedGesture == .nonEvent {
                numTimesGestureReported = 0
                lastGestureReported = predictedGesture
            }
            if predictedGesture != .nonEvent &&
                predictedConfidence >= Constants.minConfidenceThreshold {
                if predictedGesture != lastGestureReported {
                    lastGestureReported = predictedGesture
                    numTimesGestureReported = 1
                }
                else {
                    numTimesGestureReported += 1
                }
                if (numTimesGestureReported < Constants.maxOccurencesForSuppressing) {
                    gestureDataCallback?(predictedGesture, predictedConfidence)
                }
            }
        }
    }

    /// Post process the raw prediction from the model using historical context.
    private func postProcessPrediction(gestureResult: BoseMLGestureModelOutput) -> (BoseGestureType, Int) {
        for (gesture, confidence) in gestureResult.output {
            let gestureLabel = BoseGestureType.from(gesture)
            let confidencePercentage = 100.0 * confidence
            smoothedConfidence[gestureLabel] =  (smoothedConfidence[gestureLabel] ?? 0.0) * (1.0 - Constants.smoothingConstant)
            smoothedConfidence[gestureLabel]? +=  Constants.smoothingConstant * confidencePercentage
        }

        let predictedGesture = smoothedConfidence.max(by: { $0.1 < $1.1 }) ?? (.nonEvent, 0)
        if let predictedConfidence = smoothedConfidence[predictedGesture.key] {
            predictionHistory.append(predictedGesture.key)
            predictionHistory.removeFirst()
            confidenceHistory.append(predictedConfidence)
            confidenceHistory.removeFirst()
        }

        let (prediction, confidence) = mostFrequentPrediction()
        if (prediction != lastDetectedGesture) {
            numTimesGestureDetected = 1
            lastDetectedGesture = prediction
        }
        else
        {
            numTimesGestureDetected += 1
        }
        if enabledGestures.contains(prediction) &&
            numTimesGestureDetected > Constants.minOccurenecesForReporting {
            return (prediction, confidence)
        }
        return (.nonEvent, 0)
    }

    /// Report the most frequent gesture which was detected in recent history and average confidence for that gesture.
    private func mostFrequentPrediction() -> (BoseGestureType, Int) {
        var counts = [BoseGestureType: Int]()
        var averageConfidence = 0.0
        predictionHistory.forEach { counts[$0] = (counts[$0] ?? 0) + 1 }
        if let (value, hitCount) = counts.max(by: { $0.1 < $1.1 }) {
            var count = 0
            for gesture in predictionHistory {
                if gesture == value {
                    averageConfidence += confidenceHistory[count]
                }
                count += 1
            }
            return (value, Int(averageConfidence / Double(hitCount)))
        }
        // array was empty
        return (.nonEvent, 0)
    }

    /// Aggregate the sensor data in the format that the model expects.
    private func aggregateData() {
        guard let dataBuffer = aggregatedDataBuffer else {
            return
        }
        var count = 0
        for sampleIndex in 0..<Constants.samplesPerSensorDim {
            for dimIndex in 0..<Constants.sensorDimOrdering.count {
                let arr = returnSensorData(name: Constants.sensorDimOrdering[dimIndex])
                let (min_value, max_value) = returnSensorDimNormalization(name: Constants.sensorDimOrdering[dimIndex])
                let dataPoint = (arr[arr.count - Constants.samplesPerSensorDim + sampleIndex] - min_value) / (max_value - min_value)
                dataBuffer[count] = NSNumber(value: dataPoint)
                count += 1
            }
        }
    }

    /// Utility function for returning the sensor data for a single dimension.
    private func returnSensorData(name: String) -> [Double] {
        var array: [Double] = []
        switch name {
        case "accel_x":
            array = accelDataBuffer.returnDimData(name: .X)
        case "accel_y":
            array = accelDataBuffer.returnDimData(name: .Y)
        case "accel_z":
            array = accelDataBuffer.returnDimData(name: .Z)
        case "gyro_x":
            array = gyroDataBuffer.returnDimData(name: .X)
        case "gyro_y":
            array = gyroDataBuffer.returnDimData(name: .Y)
        case "gyro_z":
            array = gyroDataBuffer.returnDimData(name: .Z)
        default:
            array = []
        }
        return array
    }

    /// Return normalization constants which will be applied to the sensor data.
    private func returnSensorDimNormalization(name: String) -> (Double, Double) {
        if let index = Constants.sensorDimOrdering.lastIndex(of: name) {
            return (Constants.sensorMinValueForNormalization[index], Constants.sensorMaxValueForNormalization[index])
        } else {
            return (0.0, 1.0)
        }
    }

    /// Reset the count for nunber of new samples. This will be done after each time the model is invoked.
    private func resetSensorsNewDataCount() {
        accelDataBuffer.resetNewDataCount()
        gyroDataBuffer.resetNewDataCount()
    }
}
