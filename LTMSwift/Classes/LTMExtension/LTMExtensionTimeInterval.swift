//
//  LTMExtensionTimeInterval.swift
//  ZhiHuiKuangShan
//
//  Created by 柯南 on 2020/7/6.
//  Copyright © 2020 TianRui. All rights reserved.
//

import Foundation

extension TimeInterval {
    /// 2020/09/09
    func YYMMDDString() -> String {
        let date = Date(timeIntervalSince1970: self)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd"
        return dateFormatter.string(from: date)
    }
    /// + after - before
    func beforeAfter(day: Int) -> TimeInterval {
        self + TimeInterval(24 * 60 * 60 * (day))
    }
}
