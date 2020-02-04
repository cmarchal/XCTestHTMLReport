//
//  Date+Formatting.swift
//  XCTestHTMLReport
//
//  Created by Marchal, Cesar on 8/6/19.
//  Copyright © 2019 Tito. All rights reserved.
//

import Foundation

extension Date {

    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    var dateString: String {
        return Date.formatter.string(from: self)
    }
}
