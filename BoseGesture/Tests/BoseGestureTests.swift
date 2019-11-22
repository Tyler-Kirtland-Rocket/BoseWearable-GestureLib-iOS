//
//  BoseGestureTests.swift
//  BoseGestureTests
//
//  Created by Jorge Castellanos on 6/14/19.
//  Copyright © 2019 Bose Corporation. All rights reserved.
//

@testable import BoseGesture
import BoseWearable
import XCTest

extension Matrix {
    static let gestureTypes: [BoseGestureType] = [
        .lookUp,
        .lookDown,
        .lookLeft,
        .lookRight,
        .tiltLeft,
        .tiltRight,
        .headNod,
        .headShake,
        .nonEvent
    ]

    static func gestureIndex(_ gesture: BoseGestureType) -> Int {
        return gestureTypes.firstIndex(of: gesture) ?? -1
    }

    static func testResult() -> Matrix {
        let gestureLabels = gestureTypes.map { $0.label }
        return Matrix(rowLabels: gestureLabels, columnLabels: gestureLabels)
    }

    func add(expected: BoseGestureType, actual: BoseGestureType) {
        inc(row: Self.gestureIndex(expected), column: Self.gestureIndex(actual))
    }
}

class BoseGestureTests: XCTestCase {
    var allGestureCount = 0
    var allCorrectCount = 0
    var allIncorrectCount = 0
    var allExtraCount = 0

    static let documentsDir: URL = {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }()

    static func processCsvFile(url: URL, into testResult: Matrix) {
        print("file: \(url.lastPathComponent)")

        guard let rows = CsvDataProcessing.rows(url) else {
            XCTFail("Couldn't create a StreamReader")
            return
        }

        var expectedGesture: BoseGestureType = .nonEvent

        BoseGesture.shared.recognizer.gestureDataCallback = { gesture, timestamp in
            testResult.add(expected: expectedGesture, actual: gesture)
            expectedGesture = .nonEvent
        }

        for gestureInfo in CsvDataProcessing.transform(rows, countBeforeStart: 100, maxCountAfterEnd: 100) {
            expectedGesture = gestureInfo.type
            let startLineNumber = gestureInfo.rows.first?.lineNumber ?? 0
            BoseGesture.shared.recognizer.flush()
            for row in gestureInfo.rows {
                let acc_data = Vector(row.acc_x, row.acc_y, row.acc_z)
                let gyr_data = Vector(row.gyr_x, row.gyr_y, row.gyr_z)
                let timestamp: SensorTimestamp = UInt16(((row.lineNumber - startLineNumber) * 10) % Int(UInt16.max))
                BoseGesture.shared.recognizer.appendAccelerometer(data: acc_data, accuracy: .high, timestamp: timestamp)
                BoseGesture.shared.recognizer.appendGyroscope(data: gyr_data, accuracy: .high, timestamp: timestamp)
            }
        }
    }

    static func processCsvFileRawOutput(url: URL) {
        print("file: \(url.lastPathComponent)")

        let outputURL = documentsDir.appendingPathComponent(url.lastPathComponent)
        guard let outputFileWriter = StreamWriter(url: outputURL) else {
            XCTFail("Couldn't create a StreamWriter\nurl: \(outputURL)")
            return
        }

        print("output: \(outputURL.path)")

        guard let rows = CsvDataProcessing.rows(url) else {
            XCTFail("Couldn't create a StreamReader")
            return
        }

        BoseGesture.shared.recognizer.gestureDataCallback = { gesture, timestamp in
            outputFileWriter.append(gesture.label.appending("\n"))
        }

        let startLineNumber = 2
        for row in rows {
            outputFileWriter.append(row.toString())
            let acc_data = Vector(row.acc_x, row.acc_y, row.acc_z)
            let gyr_data = Vector(row.gyr_x, row.gyr_y, row.gyr_z)
            let timestamp: SensorTimestamp = UInt16(((row.lineNumber - startLineNumber) * 10) % Int(UInt16.max))
            BoseGesture.shared.recognizer.appendAccelerometer(data: acc_data, accuracy: .high, timestamp: timestamp)
            BoseGesture.shared.recognizer.appendGyroscope(data: gyr_data, accuracy: .high, timestamp: timestamp)
        }
    }

    func testMatrix() {
        let matrix = Matrix(rowLabels: ["row1", "row12", "row3", "row4"], columnLabels: ["col1", "col2", "col123"])
        matrix.inc(row: 0, column: 0)
        matrix.inc(row: 0, column: 1)
        matrix.inc(row: 0, column: 2)
        matrix.inc(row: 3, column: 1)
        print(matrix)
    }

    func testCsvData() {
        let bundle = Bundle(for: BoseGestureTests.self)
        guard let urls = bundle.urls(forResourcesWithExtension: "csv", subdirectory: "testData") else {
            XCTFail("Couldn't find the test data files")
            return
        }

        XCTAssertFalse(urls.isEmpty)

        let testResult = Matrix.testResult()

        for (index, url) in urls.enumerated() {
            print("\(index + 1) out of \(urls.count)")
            Self.processCsvFile(url: url, into: testResult)
        }

        print("--------------------")
        print(testResult)
    }

    func testCsvDataRawOutput() {
        let bundle = Bundle(for: BoseGestureTests.self)
        guard let urls = bundle.urls(forResourcesWithExtension: "csv", subdirectory: "testData") else {
            XCTFail("Couldn't find the test data files")
            return
        }

        XCTAssertFalse(urls.isEmpty)

        for (index, url) in urls.enumerated() {
            print("\(index + 1) out of \(urls.count)")
            Self.processCsvFileRawOutput(url: url)
        }
    }
}
