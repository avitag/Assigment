//
//  ChartViewModel.swift
//  Assigment
//
//  Created by Avinash on 19/07/2025.
//

import Foundation
import RxSwift
import RxCocoa

class ChartViewModel {
    // MARK: - Inputs
    let baseCurrency = BehaviorRelay<String>(value: "USD")
    let targetCurrency = BehaviorRelay<String>(value: "EUR")
    
    // MARK: - Outputs
    let historicalData = BehaviorRelay<[HistoricalDataPoint]>(value: [])
    let isLoading = BehaviorRelay<Bool>(value: false)
    let error = PublishRelay<String>()
    
    // MARK: - Properties
    private let disposeBag = DisposeBag()
    private let exchangeRateService = ExchangeRateService.shared
    
    init() {
        setupBindings()
    }
    
    private func setupBindings() {
        let currencyPair = Observable
            .combineLatest(baseCurrency.asObservable(), targetCurrency.asObservable())
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .distinctUntilChanged { $0.0 == $1.0 && $0.1 == $1.1 }
        
        let historicalDataObservable = currencyPair
            .flatMapLatest { base, target -> Observable<[HistoricalDataPoint]> in
                self.isLoading.accept(true)
                return self.exchangeRateService
                    .getHistoricalData(base: base, target: target)
                    .asObservable()
                    .do(
                        onNext: { _ in self.isLoading.accept(false) },
                        onError: { error in
                            self.isLoading.accept(false)
                            self.error.accept(error.localizedDescription)
                        }
                    )
            }
        
        historicalDataObservable
            .subscribe(
                onNext: { data in
                    self.historicalData.accept(data)
                },
                onError: { error in
                    self.error.accept(error.localizedDescription)
                }
            )
            .disposed(by: disposeBag)
    }

}
