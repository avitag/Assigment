//
//  CoreDataService.swift
//  Assigment
//
//  Created by Avinash on 19/07/2025.
//

import Foundation
import CoreData
import UIKit

class CoreDataService {
    
    static let shared = CoreDataService()
    
    private init() {}

    // MARK: - Core Data Stack
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Assigment")
        container.loadPersistentStores { (_, error) in
            if let error = error {
                fatalError("Core Data store failed: \(error.localizedDescription)")
            }
        }
        return container
    }()

    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    // MARK: - Save Rates
    func saveExchangeRates(base: String, rates: [CurrencyRate], date: Date) {
        
        let entity = Exchange(context: context)
        entity.base = base
        entity.timestamp = date

        for currency in rates {
            let rateEntity = Rates(context: context)
            rateEntity.target = currency.currency
            rateEntity.rates = currency.value
            entity.addToRates(rateEntity)
        }
        saveContext()
    }

    // MARK: - Fetch Rates
    func fetchExchangeRates(base: String) -> ExchangeRateResponse? {
        let request: NSFetchRequest<Exchange> = Exchange.fetchRequest()
        request.predicate = NSPredicate(format: "base == %@", base)
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]

        do {
            let result = try context.fetch(request).first
            let rates = result?.rates as? Set<Rates> ?? []
            let currencyRates = rates.compactMap({ rate in
                CurrencyRate(currency: rate.target ?? "", value: rate.rates)
            })
            return ExchangeRateResponse(base: base, date: result?.timestamp ?? Date(), rates: currencyRates)

        } catch {
            print("Core Data fetch error: \(error)")
            return nil
        }
    }
    
    // MARK: - Delete Rates
    func deleteExchangeRates(for base: String) {
        let request: NSFetchRequest<NSFetchRequestResult> = Exchange.fetchRequest()
        request.predicate = NSPredicate(format: "base == %@", base)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)

        do {
            try context.execute(deleteRequest)
        } catch {
            print("Core Data delete error: \(error)")
        }
    }

    // MARK: - Save Context
    func saveContext() {
        guard context.hasChanges else { return }
        
        do {
            try context.save()
        } catch {
            print("Core Data save failed: \(error)")
        }
    }
}
