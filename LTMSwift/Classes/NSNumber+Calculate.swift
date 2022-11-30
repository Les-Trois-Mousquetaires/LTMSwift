//
//  NSNumber+Calculate.swift
//  FBSnapshotTestCase
//
//  Created by 柯南 on 2022/11/30.
//

import Foundation
public extension NSNumber{
    //    RoundingMode : UInt {
    //        // 全向右靠，向大靠拢
    //    case ceiling = 0
    //        // 全向左靠，向小靠拢
    //    case floor = 1
    //        // 正数向左边靠，负数向右边靠
    //    case down = 2
    //        //正数向右边靠，负数向左边靠
    //    case up = 3
    //        银行家舍入法，总结：目标是偶数，可以使用四舍五入，也可以适用五舍六入，具体看哪边更接近一个偶数
    //    case halfEven = 4
    //        // 五舍六入
    //    case halfDown = 5
    //        // 四舍五入
    //    case halfUp = 6
    //    }
    
    /**
     小数位展示使用，带逗号
     
     - parameter digit 小数位数, 默认四舍五入
     */
    public func decimalDigit(_ digit: Int) -> String{
        return self.decimalDigit(digit, .halfUp, true)
    }
    
    /**
     小数位给后台传递
     
     - parameter digit 小数位数, 默认四舍五入
     */
    public func decimalDigitParam(_ digit: Int) -> String{
        return self.decimalDigit(digit, .halfUp, false)
    }
    
    /**
     小数位
     
     - parameter digit 小数位数
     - parameter mode 小数保留方式
     - parameter hasComma 是否包含逗号
     */
    private func decimalDigit(_ digit: Int, _ mode: NumberFormatter.RoundingMode, _ hasComma: Bool) -> String{
        let format = NumberFormatter.init()
        format.numberStyle = hasComma == true ? .decimal : .none // 是否带逗号
        format.minimumFractionDigits = digit // 最少小数位
        format.maximumFractionDigits = digit // 最多小数位
        format.formatterBehavior = .default
        format.roundingMode = mode
        return format.string(from: self) ?? ""
    }
    
    /**
     NSNumber 加法计算
     
     - parameter num 被加数
     */
    public func adding(num:NSNumber) -> NSNumber{
        let number1 = NSDecimalNumber(string: self.stringValue)
        let number2 = NSDecimalNumber(string: num.stringValue)
        let sum = number1.adding(number2)
        return sum
    }
    
    /**
     NSNumber 减法计算
     
     - parameter num 被减数
     */
    public func subtracting(num:NSNumber) -> NSNumber{
        let number1 = NSDecimalNumber(string: self.stringValue)
        let number2 = NSDecimalNumber(string: num.stringValue)
        let sum = number1.subtracting(number2)
        return sum
    }
    
    /**
     NSNumber 乘法计算
     
     - parameter num 被乘数
     */
    public func multiplying(num:NSNumber) -> NSNumber{
        let number1 = NSDecimalNumber(string: self.stringValue)
        let number2 = NSDecimalNumber(string: num.stringValue)
        let sum = number1.multiplying(by: number2)
        return sum
    }
    /**
     NSNumber 除法计算
     
     - parameter num 被除数
     */
    public func dividing(num:NSNumber) -> NSNumber{
        let number1 = NSDecimalNumber(string: self.stringValue)
        let number2 = NSDecimalNumber(string: num.stringValue)
        let sum = number1.dividing(by: number2)
        return sum
    }
}
