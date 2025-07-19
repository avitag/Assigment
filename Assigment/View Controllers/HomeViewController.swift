//
//  HomeViewController.swift
//  Assigment
//
//  Created by Avinash on 19/07/2025.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa


class HomeViewController: UIViewController, UIScrollViewDelegate {
    // MARK: - IBOutlets
    @IBOutlet weak var baseCurrencyButton: UIButton!
    @IBOutlet weak var targetCurrencyButton: UIButton!
    @IBOutlet weak var amountTextField: UITextField!
    @IBOutlet weak var convertedAmountTextField: UITextField!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var refreshButton: UIButton!
    @IBOutlet weak var lastUpdateLabel: UILabel!
    @IBOutlet weak var chartButton: UIBarButtonItem!
    
    var doneButton: UIBarButtonItem!
    
    // MARK: - Properties
    private let viewModel = ConverterViewModel()
    private let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
    }
    
    private func setupUI() {
        title = "Currency Exchange"
        
        
        // Setup text field
        amountTextField.keyboardType = .decimalPad
        
        // Setup buttons
        baseCurrencyButton.setTitle("EUR", for: .normal)
        targetCurrencyButton.setTitle("", for: .normal)
                
        // Add toolbar to text field
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissKeyboard))
        toolbar.setItems([doneButton], animated: false)
        amountTextField.inputAccessoryView = toolbar
    }
    
    private func setupBindings() {
        // Bind UI inputs to view model
        amountTextField.rx.controlEvent(.editingDidEnd)
            .withLatestFrom(amountTextField.rx.text.orEmpty)
            .map { Double($0) ?? 0 }
            .subscribe(onNext: { [weak self] amnt in
                self?.viewModel.amount.accept((amnt))
                self?.viewModel.fetchExchangeRates()
            })
            .disposed(by: disposeBag)

                
        refreshButton.rx.tap
            .bind(to: viewModel.refreshTrigger)
            .disposed(by: disposeBag)
        
        tableView.rx.setDelegate(self)
            .disposed(by: disposeBag)
        
        

        // Bind view model outputs to UI
        viewModel.exchangeRates
            .compactMap { $0 }
            .bind(to: tableView.rx.items(cellIdentifier: "CurrencyCell")) { index, currency, cell in
                
                guard let cell = cell as? CurrencyCell else { return }
                cell.configure(code:currency.currency , rate: currency.value)
            }
            .disposed(by: disposeBag)
        
        viewModel.convertedAmount
            .map({String($0)})
            .bind(to: convertedAmountTextField.rx.text)
            .disposed(by: disposeBag)
                
        viewModel.lastUpdateTime
            .map({$0?.formatted(date: .abbreviated, time: .shortened)})
            .bind(to: lastUpdateLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.error
            .subscribe(onNext: { [weak self] errorMessage in
                self?.showError(message: errorMessage)
            })
            .disposed(by: disposeBag)
        
        // Handle table view selection
        tableView.rx.modelSelected(CurrencyRate.self)
            .subscribe(onNext: { [weak self] currency in
                guard let self = self else { return }
                
                // Set selected target currency
                self.viewModel.targetCurrency.accept(currency.currency)
                self.targetCurrencyButton.setTitle(currency.currency, for: .normal)
                
                // Get amount from text field
                let amount = Double(self.amountTextField.text ?? "") ?? 0
                let convertedAmount = amount * currency.value
                
                // Display converted amount
                self.convertedAmountTextField.text = String(format: "%.2f", convertedAmount)
            })
            .disposed(by: disposeBag)
                
        chartButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.showChart()
            })
            .disposed(by: disposeBag)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    private func showError(message: String) {
        DispatchQueue.main.async { [weak self] in
            let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self?.present(alert, animated: true)
        }
    }
    
    private func showChart() {

    }
}
