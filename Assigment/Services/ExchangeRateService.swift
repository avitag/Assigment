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

    // MARK: - Get historical data for chart
    func getHistoricalData(base: String, target: String) -> Observable<[HistoricalDataPoint]> {
        return Observable.create { observer in
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"

            let endDate = Date()
            guard let startDate = Calendar.current.date(byAdding: .day, value: -6, to: endDate) else {
                observer.onError(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid start date"]))
                return Disposables.create()
            }

            let startString = formatter.string(from: startDate)
            let endString = formatter.string(from: endDate)

            var components = URLComponents(string: "\(self.baseURL)/timeseries")
            components?.queryItems = [
                URLQueryItem(name: "access_key", value: self.apiKey),
                URLQueryItem(name: "base", value: base),
                URLQueryItem(name: "symbols", value: target),
                URLQueryItem(name: "start_date", value: startString),
                URLQueryItem(name: "end_date", value: endString)
            ]

            guard let url = components?.url else {
                observer.onError(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
                return Disposables.create()
            }

            let request = URLRequest(url: url)

            let task = URLSession.shared.dataTask(with: request) { data, _, error in
                if let error = error {
                    observer.onError(error)
                    return
                }

                guard let data = data else {
                    observer.onError(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data returned"]))
                    return
                }

                do {
                    
                    let bundle = Bundle.main.url(forResource: "History", withExtension: "json")
                    let bundledata = try Data(contentsOf: bundle!)
                    let decoder = JSONDecoder()
                    let response = try decoder.decode(HistoricalResponse.self, from: bundledata)

                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd"

                    var points: [HistoricalDataPoint] = []
                    for rate in response.rates {
                        if let date = formatter.date(from: rate.date), let r = rate.rates.first(where: {$0.currency == "USD"}){
                            points.append(HistoricalDataPoint(date: date, rate:r.rate ))
                        }
                    }

                    points.sort { $0.date < $1.date }
                    observer.onNext(points)
                    observer.onCompleted()
                } catch {
                    observer.onError(error)
                }
            }

            task.resume()

            return Disposables.create {
                task.cancel()
            }
        }
    }


//MARK: Fetching Latest Exchange Rate API
    func fetchExchangeRates(base: String) -> Observable<ExchangeRateResponse> {
        return Observable.create { observer in
            
            var components = URLComponents(string: "\(self.baseURL)/latest")!
            components.queryItems = [
                URLQueryItem(name: "access_key", value: self.apiKey),
                //MARK: Removing the base
                // As free account don't support the base query
                // URLQueryItem(name: "base", value: base),
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

