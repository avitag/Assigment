//
//  ConverterViewModel.swift
//  Assigment
//
//  Created by Avinash on 19/07/2025.
//

import Foundation
import RxSwift
import RxCocoa

class ConverterViewModel {
    // MARK: - Variables Input
    let baseCurrency = BehaviorRelay<String>(value: "USD")
    let targetCurrency = BehaviorRelay<String>(value: "EUR")
    let amount = BehaviorRelay<Double>(value: 1.0)
    let refreshTrigger = PublishSubject<Void>()

    // MARK: - Variables Outputs
    let convertedAmount = BehaviorRelay<Double>(value: 0.0)
    let exchangeRates = BehaviorRelay<[CurrencyRate]?>(value: [])
    let isLoading = BehaviorRelay<Bool>(value: false)
    let error = PublishRelay<String>()
    let lastUpdateTime = BehaviorRelay<Date?>(value: nil)

    // MARK: - Variables Services
    private var exchangeRateService = ExchangeRateService.shared
    private var coreDataService = CoreDataService.shared
    private let disposeBag = DisposeBag()

    init() {
        setupBindings()
        
        //Fetch Rates on first load
        fetchExchangeRates()
        
        //Setup Auto referesh of the API Call
        setupAutoRefresh()
        
    }
    
    init(
        exchangeRateService: ExchangeRateService = ExchangeRateService.shared,
        coreDataService: CoreDataService = CoreDataService.shared
    ) {
        self.exchangeRateService = exchangeRateService
        self.coreDataService = coreDataService
        setupBindings()
        fetchExchangeRates()
        setupAutoRefresh()
    }


    // MARK: - Setup Bindings
    private func setupBindings() {
        Observable.combineLatest(baseCurrency, targetCurrency, amount)
            .subscribe(onNext: { [weak self] base, target, amount in
                self?.convert(base: base, to: target, amount: amount)
            })
            .disposed(by: disposeBag)
        
        refreshTrigger
            .withLatestFrom(baseCurrency)
            .do(onNext: { _ in self.isLoading.accept(true) })
            .flatMapLatest { base in
                self.exchangeRateService.fetchExchangeRates(base: base)
                    .do(onNext: {[weak self] response in
                        self?.exchangeRates.accept(response.rates)
                        self?.isLoading.accept(false)
                        self?.lastUpdateTime.accept(response.date)
                    })
                    .catch { error in
                        self.error.accept(error.localizedDescription)
                        return Observable.empty()
                    }
            }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] response in
                
                self?.exchangeRates.accept(response.rates)
                self?.isLoading.accept(false)
                self?.lastUpdateTime.accept(response.date)
            })
            .disposed(by: disposeBag)
    }

    // MARK: - Actions
    func fetchExchangeRates() {
        isLoading.accept(true)
        exchangeRateService.fetchExchangeRates(base: baseCurrency.value)
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] response in
                
                self?.exchangeRates.accept(response.rates)
                self?.isLoading.accept(false)
                self?.lastUpdateTime.accept(response.date)
            }, onError: { [weak self] error in
                self?.isLoading.accept(false)
                self?.error.accept(error.localizedDescription)
            })
            .disposed(by: disposeBag)
    }

    // MARK: - Auto Refresh Every 5 Minutes
    private func setupAutoRefresh() {
        Observable<Int>.interval(.seconds(60*5), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.fetchExchangeRates()
            })
            .disposed(by: disposeBag)
    }

    private func convert(base: String, to target: String, amount: Double) {
        
        if let rate = exchangeRates.value?.first(where: {$0.currency == target})?.value {
            let converted = rate * amount
            convertedAmount.accept(converted)
        }
    }
}

class MockExchangeRateService: ExchangeRateService {
    var shouldFail = false
    var mockRates: [CurrencyRate] = []
    var mockDate: Date = Date()

    override func fetchExchangeRates(base: String) -> Observable<ExchangeRateResponse> {
        if shouldFail {
            return Observable.error(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Mock error"]))
        } else {
            let response = ExchangeRateResponse(base: base, date: mockDate, rates: mockRates)
            return Observable.just(response)
        }
    }
}
