//
//  ChartLabelDateFormatter.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 06.03.17.
//  Copyright © 2017 Modum. All rights reserved.
//

import Charts

/* Custom formatter for LineChartView */
class ChartLabelDateFormatter : NSObject, IAxisValueFormatter {
    
    // MARK: IAxisValueFormatter
    
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd hh:mm"
        let date = Date(timeIntervalSince1970: TimeInterval(value))
        return dateFormatter.string(from: date)
    }
    
}
