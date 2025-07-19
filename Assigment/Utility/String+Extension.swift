//
//  String+Extension.swift
//  Assigment
//
//  Created by Avinash on 19/07/2025.
//

import Foundation

extension String{
    
    func conversion(format: String) -> Date{
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.date(from: self) ?? Date()
    }
}
