//
//  ExchangeRateService.swift
//  Assigment
//
//  Created by Avinash on 19/07/2025.
//

import Foundation
import RxSwift
import RxCocoa

class ExchangeRateService {
    static let shared = ExchangeRateService()
    private let baseURL = "https://api.exchangeratesapi.io/v1"
    private let apiKey = "2d99045bfc7f32bfffd9f02e316c5f6d"


//MARK: Fetching Latest Exchange Rate API
    func fetchExchangeRates(base: String) -> Observable<ExchangeRateResponse> {
        return Observable.create { observer in
            
            var components = URLComponents(string: "\(self.baseURL)/latest")!
            components.queryItems = [
                URLQueryItem(name: "access_key", value: self.apiKey),
                URLQueryItem(name: "base", value: base),
                URLQueryItem(name: "format", value: "1")
            ]

            guard let url = components.url else {
                observer.onError(NetworkError.invalidURL)
                return Disposables.create()
            }

            let task = URLSession.shared.dataTask(with: url) { data, response, error in
                if let data = data {
                    do {
                        let response = try JSONDecoder().decode(ExchangeRateResponse.self, from: data)
                        CoreDataService.shared.saveExchangeRates(base: base, rates: response.rates, date: response.date)
                        observer.onNext(response)
                        observer.onCompleted()
                    } catch {
                        observer.onError(error)
                    }
                } else if let error = error {
                    if let response = CoreDataService.shared.fetchExchangeRates(base: base){
                        observer.onNext(response)
                        observer.onCompleted()
                    }
                    else{
                        print("Network error: \(error.localizedDescription)")
                        observer.onError(error)
                    }

                } else {
                    observer.onError(error ?? NetworkError.invalidURL)
                }
            }

            task.resume()
            return Disposables.create { task.cancel() }
        }
    }

}

