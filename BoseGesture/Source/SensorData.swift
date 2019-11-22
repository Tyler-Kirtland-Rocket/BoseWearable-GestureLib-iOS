//
//  SensorData.swift
//  BoseGesture
//
//  Created by Vinod Radhakrishnan on 6/11/19.
//  Copyright © 2019 Bose Corporation. All rights reserved.
//

import BoseWearable

/// Enum for sensor axes (X-, Y-, Z- and optionally W-)
enum SensorDim {

    // case X- axis
    case X

    // case Y- axis
    case Y

    // case Z- axis
    case Z

    // case W- axis
    case W
}

// Enum for types of data vectors - 3D vectors and 4D quaternions
enum DataType {

    case vector3d

    case quaternion
}

// One sensor sample is a dictionary, for example
// [.X: 0.0, .Y: 1.0, .Z: 2.0, .W: 0.0]
typealias SensorSample = [SensorDim: Double]

// One sensor vector is an aggregate of sensor samples, for example
// [.X: [0.0, 0.2, 0.4, 0.6 ...], .Y: [0.0, 0.1, ...], ...]
typealias SensorVector = [SensorDim: [Double]]

struct SensorData {
    private var data: SensorVector = [:]
    private var prevTimeStamp: UInt16
    private var newDataSampleCount: Int

    // Initialize SensorData struct
    init (bufferLength: Int, dataType: DataType) {
        data[.X] = [Double](repeating: 0.0, count: bufferLength)
        data[.Y] = [Double](repeating: 0.0, count: bufferLength)
        data[.Z] = [Double](repeating: 0.0, count: bufferLength)
        if dataType == .quaternion {
            data[.W] = [Double](repeating: 0.0, count: bufferLength)
        }
        prevTimeStamp = 0
        newDataSampleCount = 0
    }

    // Flush data
    mutating func flushData() {
        for (key, _) in data {
            data[key] = data[key]?.map { _ in 0 }
        }
        prevTimeStamp = 0
        resetNewDataCount()
    }

    // Append new data sample to buffer
    mutating func appendData(timeStamp: SensorTimestamp, vector: Vector, modelSamplePeriodMs: Int) {
        var interpolationFactor = 1
        var decimationFactor = 1

        if self.prevTimeStamp == 0 {
            prevTimeStamp = timeStamp
        }

        // convert Vector to SensorSample
        let sensorSample = convertVectorToSample(vector: vector)

        if timeStamp < prevTimeStamp {
            // Handle wraparounds
            interpolationFactor = Int(round(Double(Int(timeStamp) + 65535 - Int(prevTimeStamp)) / Double(modelSamplePeriodMs)))
            decimationFactor = Int(round(Double(modelSamplePeriodMs) / Double(Int(timeStamp) + 65535 - Int(prevTimeStamp))))
        }
        else if timeStamp > prevTimeStamp {
            interpolationFactor = Int(round(Double(Int(timeStamp) - Int(prevTimeStamp)) / Double(modelSamplePeriodMs)))
            decimationFactor = Int(round(Double(modelSamplePeriodMs) / Double(Int(timeStamp) - Int(prevTimeStamp))))
        }

        for index in stride(from: 1, through: interpolationFactor - 1, by: 1) {
            let scale = Double(index) / Double(interpolationFactor)
            for (key, array) in data {
                let lastValue = array.last ?? 0.0
                let sampleData = sensorSample[key] ?? 0.0
                data[key]?.append(lastValue + scale * (sampleData - lastValue))
                data[key]?.removeFirst()
            }
            incrementNewDataCount()
        }

        if decimationFactor <= 1 {
            prevTimeStamp = timeStamp
            for (key, _) in data {
                let sampleData = sensorSample[key] ?? 0.0
                data[key]?.append(sampleData)
                data[key]?.removeFirst()
            }
            incrementNewDataCount()
        }
    }

    mutating private func incrementNewDataCount() {
        self.newDataSampleCount += 1
    }

    mutating func resetNewDataCount() {
        self.newDataSampleCount = 0
    }

    mutating func getNewDataCount() -> Int {
        return self.newDataSampleCount
    }

    func returnDimData(name: SensorDim) -> [Double] {
        if let array = self.data[name] {
            return array
        }
        else {
            return []
        }
    }
}

func convertVectorToSample(vector: Vector) -> SensorSample {
    var sensorSample: SensorSample = [:]

    sensorSample[.X] = vector.x
    sensorSample[.Y] = vector.y
    sensorSample[.Z] = vector.z

    return sensorSample
}
