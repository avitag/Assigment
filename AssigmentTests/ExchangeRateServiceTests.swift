//
//  ExchangeRateServiceTests.swift
//  Assigment
//
//  Created by Avinash on 19/07/2025.
//

import Foundation
import XCTest
import RxSwift
@testable import Assigment

final class ExchangeRateServiceTests: XCTestCase {
    var disposeBag: DisposeBag!
    var service: ExchangeRateService!

    override func setUp() {
        super.setUp()
        disposeBag = DisposeBag()
        service = ExchangeRateService.shared
    }

    override func tearDown() {
        disposeBag = nil
        service = nil
        super.tearDown()
    }

    func testFetchExchangeRates_Success() {
        let expectation = self.expectation(description: "Should return exchange rates")

        let base = "EUR"
        var receivedResponse: ExchangeRateResponse?

        service.fetchExchangeRates(base: base)
            .subscribe(onNext: { response in
                receivedResponse = response
                expectation.fulfill()
            }, onError: { error in
                XCTFail("Expected success, got error: \(error)")
            })
            .disposed(by: disposeBag)

        waitForExpectations(timeout: 5.0)

        XCTAssertNotNil(receivedResponse)
        XCTAssertEqual(receivedResponse?.base, base, "Base currency should match")
        XCTAssertFalse(receivedResponse?.rates.isEmpty ?? true, "Rates should not be empty")
    }
}
