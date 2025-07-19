//
//  DateValueFormatter.swift
//  Assigment
//
//  Created by Avinash on 19/07/2025.
//

import Foundation
import DGCharts

class DateValueFormatter: AxisValueFormatter {
    private let formatter: DateFormatter

    init() {
        formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
    }

    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        return formatter.string(from: Date(timeIntervalSince1970: value))
    }
}
