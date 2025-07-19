//
//  ExchangeRateResponse.swift
//  Assigment
//
//  Created by Avinash on 19/07/2025.
//

import Foundation

struct ExchangeRateResponse: Codable {
    let base: String
    let date: Date
    let rates: [CurrencyRate]

    // Custom decoding to convert dictionary into array
    private enum CodingKeys: String, CodingKey {
        case base
        case date
        case rates
    }

    init(base: String, date: Date, rates: [CurrencyRate]) {
        self.base = base
        self.date = date
        self.rates = rates
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        base = try container.decode(String.self, forKey: .base)
        let dateString = try container.decode(String.self, forKey: .date)
        date = dateString.conversion(format: "yyyy-MM-dd")
        let rateDict = try container.decode([String: Double].self, forKey: .rates)
        rates = rateDict.map { CurrencyRate(currency: $0.key, value: $0.value) }
    }

    // Optional: encode back to dictionary if needed
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(base, forKey: .base)
        try container.encode(date, forKey: .date)
        let rateDict = Dictionary(uniqueKeysWithValues: rates.map { ($0.currency, $0.value) })
        try container.encode(rateDict, forKey: .rates)
    }
}

extension String{
    
    func conversion(format: String) -> Date{
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.date(from: self) ?? Date()
    }
}
