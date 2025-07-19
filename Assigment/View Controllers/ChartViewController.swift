//
//  ChartViewController.swift
//  Assigment
//
//  Created by Avinash on 19/07/2025.
//

import Foundation
import UIKit
import DGCharts
import RxSwift
import RxCocoa

class ChartViewController: UIViewController {

    @IBOutlet weak var lineChartView: LineChartView!

    private let viewModel = ChartViewModel()
    private let disposeBag = DisposeBag()
   
   
    var baseCurrency: String = "USD"  // default or set externally
    var targetCurrency: String = "EUR"  // for comparison

    override func viewDidLoad() {
        super.viewDidLoad()
        bindViewModel()
    }

    private func bindViewModel() {
        viewModel.baseCurrency.accept(baseCurrency)
        viewModel.targetCurrency.accept(targetCurrency)
        viewModel.historicalData
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] dataPoints in
                self?.updateChart(dataPoints)
            })
            .disposed(by: disposeBag)

        viewModel.error
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] message in
                let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self?.present(alert, animated: true)
            })
            .disposed(by: disposeBag)
    }

    private func updateChart(_ dataPoints: [HistoricalDataPoint]) {
        let entries = dataPoints.map { ChartDataEntry(x: $0.date.timeIntervalSince1970, y: $0.rate) }

        let dataSet = LineChartDataSet(entries: entries, label: "Rate")
        dataSet.colors = [.systemBlue]
        dataSet.circleColors = [.systemBlue]
        dataSet.circleRadius = 4
        dataSet.lineWidth = 2

        let data = LineChartData(dataSet: dataSet)
        lineChartView.data = data

        lineChartView.xAxis.valueFormatter = DateValueFormatter()
        lineChartView.xAxis.labelPosition = .bottom
        lineChartView.rightAxis.enabled = false
        lineChartView.animate(xAxisDuration: 0.5)
    }
}
