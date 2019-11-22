//
//  Matrix.swift
//  BoseGestur
//
//  Created by Ilya Belenkiy on 10/7/19.
//  Copyright © 2019 Bose Corporation. All rights reserved.
//

class Matrix: CustomStringConvertible {
    private var data: [[Int]] = []
    let rowLabels: [String]
    let columnLabels: [String]

    init(rowLabels: [String], columnLabels: [String]) {
        self.rowLabels = rowLabels
        self.columnLabels = columnLabels
        let row = [Int](repeating: 0, count: columnLabels.count)
        data = [[Int]](repeating: row, count: rowLabels.count)
    }

    func inc(row: Int, column: Int) {
        data[row][column] += 1
    }

    var description: String {
        let minColumnLength = 7
        let margin = 2
        let rowLabelMaxLength = rowLabels.reduce(0, { max($0, $1.count) })
        let rowLabelPaddingLength = rowLabelMaxLength + margin

        func columnPaddingLength(_ index: Int) -> Int {
            max(columnLabels[index].count + margin, minColumnLength)
        }

        func paddedString(_ str: String, toLength length: Int) -> String {
            let strLength = str.count
            guard strLength < length else { return str }
            return String(repeating: " ", count: length - strLength).appending(str)
        }

        var output = paddedString("", toLength: rowLabelPaddingLength)
        for (column, columnLabel) in columnLabels.enumerated() {
            let label =  paddedString(columnLabel, toLength: columnPaddingLength(column))
            output.append("\(label)")
        }
        output.append("\n")

        for (row, rowLabel) in rowLabels.enumerated() {
            let label = paddedString(rowLabel, toLength: rowLabelPaddingLength)
            output.append("\(label)")
            for column in columnLabels.indices {
                let dataStr = paddedString(String(data[row][column]), toLength: columnPaddingLength(column))
                output.append(dataStr)
            }
            output.append("\n")
        }

        return output
    }
}
