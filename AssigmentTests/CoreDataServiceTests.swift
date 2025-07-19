//
//  CoreDataServiceTests.swift
//  AssigmentTests
//
//  Created by Avinash on 19/07/2025.
//

import XCTest
@testable import Assigment

final class CoreDataServiceTests: XCTestCase {

    var coreDataService: CoreDataService!

    override func setUp() {
        super.setUp()
        coreDataService = CoreDataService.shared
    }

    override func tearDown() {
        super.tearDown()
        coreDataService = nil
    }

    func testSaveAndFetchExchangeRates() {
        // Given
        let baseCurrency = "USD"
        let sampleRates = [
            CurrencyRate(currency: "EUR", value: 0.85),
            CurrencyRate(currency: "JPY", value: 110.0)
        ]
        let date = Date()

        // When
        coreDataService.saveExchangeRates(base: baseCurrency, rates: sampleRates, date: date)

        // Then
        let fetched = coreDataService.fetchExchangeRates(base: baseCurrency)

        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.base, baseCurrency)
        XCTAssertEqual(fetched?.rates.count, 2)

        let eurRate = fetched?.rates.first(where: { $0.currency == "EUR" })
        XCTAssertEqual(eurRate?.value, 0.85)
    }

    func testDeleteExchangeRates() {
        // Given
        let baseCurrency = "USD"
        let sampleRates = [
            CurrencyRate(currency: "GBP", value: 0.75)
        ]
        let date = Date()

        coreDataService.saveExchangeRates(base: baseCurrency, rates: sampleRates, date: date)
        XCTAssertNotNil(coreDataService.fetchExchangeRates(base: baseCurrency))

        // When
        coreDataService.deleteExchangeRates(for: baseCurrency)

        // Then
        let fetchedAfterDelete = coreDataService.fetchExchangeRates(base: baseCurrency)
        XCTAssertNil(fetchedAfterDelete)
    }

    func testSaveContextDoesNotCrash() {
        // Given
        let rate = Rates(context: coreDataService.context)
        rate.target = "INR"
        rate.rates = 83.0

        // When
        XCTAssertNoThrow(coreDataService.saveContext())
    }
}
