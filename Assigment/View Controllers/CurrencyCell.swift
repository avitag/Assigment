//
//  CurrencyCell.swift
//  Assigment
//
//  Created by Avinash on 19/07/2025.
//

import Foundation
import UIKit

class CurrencyCell: UITableViewCell {
    
    @IBOutlet weak var currencyCode: UILabel!
    @IBOutlet weak var currencyRate: UILabel!

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    // MARK: - Configuration
    func configure(code: String, rate: Double) {
        currencyCode.text = code
        currencyRate.text = String(format: "%.4f", rate)
    }
}
