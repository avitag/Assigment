//
//  ConverterViewModelTests.swift
//  AssigmentTests
//
//  Created by Avinash on 19/07/2025.
//

import XCTest
import RxSwift
import RxBlocking
@testable import Assigment

final class ConverterViewModelTests: XCTestCase {
    
    var viewModel: ConverterViewModel!
    var mockService: MockExchangeRateService!
    var disposeBag: DisposeBag!

    override func setUp() {
        super.setUp()
        mockService = MockExchangeRateService()
        disposeBag = DisposeBag()
    }

    override func tearDown() {
        viewModel = nil
        mockService = nil
        disposeBag = nil
        super.tearDown()
    }

    func testFetchExchangeRates_Success() {
        // Given
        let expectedRates = [CurrencyRate(currency: "EUR", value: 0.9)]
        let expectedDate = Date()
        mockService.mockRates = expectedRates
        mockService.mockDate = expectedDate

        viewModel = ConverterViewModel(exchangeRateService: mockService)

        // When
        let expectation = expectation(description: "Rates fetched")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Then
            XCTAssertEqual(self.viewModel.exchangeRates.value?.count, 1)
            XCTAssertEqual(self.viewModel.exchangeRates.value?.first?.currency, "EUR")
            XCTAssertEqual(self.viewModel.lastUpdateTime.value, expectedDate)
            XCTAssertFalse(self.viewModel.isLoading.value)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2.0)
    }

    func testFetchExchangeRates_Failure() {
        // Given
        mockService.shouldFail = true

        viewModel = ConverterViewModel(exchangeRateService: mockService)

        // When
        let expectation = expectation(description: "Error received")

        viewModel.error
            .subscribe(onNext: { error in
                XCTAssertEqual(error, "Mock error")
                expectation.fulfill()
            })
            .disposed(by: disposeBag)

        wait(for: [expectation], timeout: 2.0)
    }

    func testConversionLogic() {
        // Given
        let rate = CurrencyRate(currency: "EUR", value: 2.0)
        mockService.mockRates = [rate]
        viewModel = ConverterViewModel(exchangeRateService: mockService)

        // When
        let expectation = expectation(description: "Conversion complete")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.viewModel.amount.accept(5.0) // USD to EUR
            XCTAssertEqual(self.viewModel.convertedAmount.value, 10.0)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2.0)
    }
}


