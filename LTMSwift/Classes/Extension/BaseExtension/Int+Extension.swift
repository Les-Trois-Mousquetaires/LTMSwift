//
//  Int+Extension.swift
//  LTMSwift
//
//  Created by coenen on 2026/10/12.
//

import Foundation

public extension Int {
    // 1...99 转换为中文数字；其他范围返回十进制文本。
    var uppercaseChineseNumber: String {
        let digits = ["零", "一", "二", "三", "四", "五", "六", "七", "八", "九"]
        guard self > 0, self < 100 else { return String(self) }
        if self < 10 { return digits[self] }
        if self == 10 { return "十" }
        if self < 20 { return "十" + digits[self % 10] }
        return digits[self / 10] + "十" + (self % 10 == 0 ? "" : digits[self % 10])
    }
}
