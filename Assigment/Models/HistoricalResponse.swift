//
//  HistoricalResponse.swift
//  Assigment
//
//  Created by Avinash on 19/07/2025.
//

import Foundation


struct HistoricalResponse: Codable {
    let success: Bool
    let timeseries: Bool
    let startDate: String
    let endDate: String
    let base: String
    let rates: [DailyRates]

    enum CodingKeys: String, CodingKey {
        case success
        case timeseries
        case startDate = "start_date"
        case endDate = "end_date"
        case base
        case rates
    }

    // Custom decoding to transform dictionary into array
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        success = try container.decode(Bool.self, forKey: .success)
        timeseries = try container.decode(Bool.self, forKey: .timeseries)
        startDate = try container.decode(String.self, forKey: .startDate)
        endDate = try container.decode(String.self, forKey: .endDate)
        base = try container.decode(String.self, forKey: .base)

        let rawRates = try container.decode([String: [String: Double]].self, forKey: .rates)
        rates = rawRates.map { date, rateDict in
            let currencyRates = rateDict.map { Rate(currency: $0.key, rate: $0.value) }
            return DailyRates(date: date, rates: currencyRates)
        }.sorted(by: { $0.date < $1.date }) // Optional: sort by date
    }
}

struct DailyRates: Codable {
    let date: String
    let rates: [Rate]
}

struct Rate: Codable {
    let currency: String
    let rate: Double
}
