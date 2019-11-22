//
//  CsvDataProcessing.swift
//  BoseGestureTests
//
//  Created by Ilya Belenkiy on 9/30/19.
//  Copyright © 2019 Bose Corporation. All rights reserved.
//

import BoseWearable
import BoseGesture

class StreamReader: Sequence, IteratorProtocol {
    let encoding: String.Encoding
    let chunkSize: Int
    let fileHandle: FileHandle
    var buffer: Data
    var bufferStartIndex: Data.Index
    let delimPattern : Data
    var isAtEOF = false

    init?(url: URL, delimeter: String = "\r\n", encoding: String.Encoding = .utf8, chunkSize: Int = 4096) {
        guard let fileHandle = try? FileHandle(forReadingFrom: url) else { return nil }
        guard let delimPattern = delimeter.data(using: encoding) else { return nil }

        self.fileHandle = fileHandle
        self.chunkSize = chunkSize
        self.encoding = encoding
        buffer = Data(capacity: chunkSize)
        bufferStartIndex = buffer.startIndex
        self.delimPattern = delimPattern
    }

    deinit {
        fileHandle.closeFile()
    }

    func rewind() {
        fileHandle.seek(toFileOffset: 0)
        buffer.removeAll(keepingCapacity: true)
        isAtEOF = false
    }

    func next() -> String? {
        while !isAtEOF {
            if let range = buffer.range(of: delimPattern, options: [], in: bufferStartIndex..<buffer.endIndex) {
                let subData = buffer.subdata(in: bufferStartIndex..<range.lowerBound)
                let line = String(data: subData, encoding: encoding)
                bufferStartIndex = range.upperBound
                return line
            }
            else {
                let tempData = fileHandle.readData(ofLength: chunkSize)
                if tempData.isEmpty {
                    isAtEOF = true
                    let subData = buffer.subdata(in: bufferStartIndex..<buffer.endIndex)
                    return subData.isEmpty ? nil : String(data: subData, encoding: encoding)
                }
                else {
                    buffer.removeSubrange(buffer.startIndex..<bufferStartIndex)
                    bufferStartIndex = buffer.startIndex
                    buffer.append(tempData)
                }
            }
        }
        return nil
    }
}

class StreamWriter {
    let fileHandle: FileHandle
    let encoding: String.Encoding

    init?(url: URL, encoding: String.Encoding = .utf8) {
        do {
            if FileManager.default.fileExists(atPath: url.path) {
                try? FileManager.default.removeItem(at: url)
            }
            guard FileManager.default.createFile(atPath: url.path, contents: nil, attributes: nil) else { return nil }
            self.fileHandle = try FileHandle(forWritingTo: url)
            self.encoding = encoding
        }
        catch {
            print(error)
            return nil
        }
    }

    func append(_ string: String) {
        guard let data = string.data(using: encoding) else { fatalError("Couldn't convert \(string) to Data") }
        fileHandle.write(data)
    }

    deinit {
        fileHandle.closeFile()
    }
}

struct DataRow {
    let lineNumber: Int
    let acc_x: Double
    let acc_y: Double
    let acc_z: Double
    let gyr_x: Double
    let gyr_y: Double
    let gyr_z: Double
    let rot_x: Double
    let rot_y: Double
    let rot_z: Double
    let rot_w: Double
    let gesture: String

    init?(_ line: String, _ lineNumber: Int) {
        let components = line.components(separatedBy: ",")
        guard components.count >= 12 else { return nil }
        var index = 0

        self.lineNumber = lineNumber

        guard let acc_x = Double(components[index]) else { return nil }
        self.acc_x = acc_x
        index += 1

        guard let acc_y = Double(components[index]) else { return nil }
        self.acc_y = acc_y
        index += 1

        guard let acc_z = Double(components[index]) else { return nil }
        self.acc_z = acc_z
        index += 1

        guard let gyr_x = Double(components[index]) else { return nil }
        self.gyr_x = gyr_x
        index += 1

        guard let gyr_y = Double(components[index]) else { return nil }
        self.gyr_y = gyr_y
        index += 1

        guard let gyr_z = Double(components[index]) else { return nil }
        self.gyr_z = gyr_z
        index += 1

        guard let rot_x = Double(components[index]) else { return nil }
        self.rot_x = rot_x
        index += 1

        guard let rot_y = Double(components[index]) else { return nil }
        self.rot_y = rot_y
        index += 1

        guard let rot_z = Double(components[index]) else { return nil }
        self.rot_z = rot_z
        index += 1

        guard let rot_w = Double(components[index]) else { return nil }
        self.rot_w = rot_w
        index += 1

        // skip gyr_n_sm
        index += 1

        gesture = components[index]
        index += 1
    }

    func toString() -> String {
        let str = [acc_x, acc_y, acc_z, gyr_x, gyr_y, gyr_z, rot_x, rot_y, rot_z, rot_w]
            .reduce(into: "", { res, num in res.append("\(num),") })
        return "\(str)\(gesture)\n"
    }
}

struct GestureInfo {
    let type: BoseGestureType
    let rows: [DataRow]

    init?(gesture: String, rows: [DataRow]) {
        switch gesture {
        case "look_up":
            type = .lookUp
        case "look_down":
            type = .lookDown
        case "look_left":
            type = .lookLeft
        case "look_right":
            type = .lookRight
        case "head_nod":
            type = .headNod
        case "head_shake":
            type = .headShake
        case "tilt_left":
            type = .tiltLeft
        case "tilt_right":
            type = .tiltRight
        default:
            return nil
        }

        self.rows = rows
    }
}

class CsvDataProcessing {
    static func rows(_ url: URL) -> AnySequence<DataRow>? {
        return StreamReader(url: url).map(Self.rows)
    }

    static func rows(_ lines: StreamReader) -> AnySequence<DataRow> {
        var lineNumber = 2
        let res = lines.dropFirst().lazy.compactMap { (line) -> DataRow? in
            guard let res = DataRow(line, lineNumber) else {
                print("Couldn't create a DataRow for line \(lineNumber):\n\(line)")
                return nil
            }

            lineNumber += 1
            return res
        }
        return AnySequence(res)
    }

    static func transform(_ rows: AnySequence<DataRow>, countBeforeStart: Int, maxCountAfterEnd: Int) -> AnySequence<GestureInfo> {
        var buffer: [DataRow] = []
        let iterator = rows.makeIterator()

        return AnySequence {
            AnyIterator<GestureInfo> {
                func next() -> (String, [DataRow])?  {
                    var doneCountBefore = false
                    while let row = iterator.next(), !doneCountBefore {
                        buffer.append(row)
                        if row.gesture != "NON" {
                            doneCountBefore = true
                        }
                        else if buffer.count > countBeforeStart {
                            buffer.removeFirst()
                        }
                    }

                    guard let gesture = buffer.last?.gesture else {
                        return nil
                    }

                    var sameGesture = true
                    while let row = iterator.next(), sameGesture {
                        buffer.append(row)
                        if row.gesture != gesture {
                            sameGesture = false
                        }
                    }

                    var countAfter = 1
                    while countAfter < maxCountAfterEnd, let row = iterator.next(), row.gesture == "NON" {
                        buffer.append(row)
                        countAfter += 1
                    }

                    let res = buffer
                    buffer.removeAll()

                    return (gesture, res)
                }

                repeat {
                    if let value = next() {
                        if let res = GestureInfo(gesture: value.0, rows: value.1) {
                            return res
                        }
                    }
                    else {
                        return nil
                    }
                }
                while true
            }
        }
    }
}
