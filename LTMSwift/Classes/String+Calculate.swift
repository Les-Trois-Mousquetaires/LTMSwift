//
//  String+Calculate.swift
//  LTMSwift
//
//  Created by 柯南 on 2022/11/30.
//

import Foundation
public extension String {
    enum RoundingType : UInt {
        case plain//取整
        case down//只舍不入
        case up//只入不舍
        case bankers//四舍五人
    }
    
    /**
     字符串转NSNumber
     
     - parameter digit 小数位数, 默认四舍五入
     */
    func number() -> NSNumber{
        return self.number(.halfUp)
    }
    
    /**
     小数位
     
     */
    private func number(_ mode: NumberFormatter.RoundingMode) -> NSNumber{
        let format = NumberFormatter.init()
        format.formatterBehavior = .default
        format.roundingMode = mode
        
        return format.number(from: self) ?? 0
    }
    
    /**
     加
     */
    func add(num:String) -> String {
        let number1 = NSDecimalNumber(string: self)
        let number2 = NSDecimalNumber(string: num)
        let summation = number1.adding(number2)
        return summation.stringValue
    }
    /**
     减
     */
    func minus(num:String) -> String {
        let number1 = NSDecimalNumber(string: self)
        let number2 = NSDecimalNumber(string: num)
        let summation = number1.subtracting(number2)
        return summation.stringValue
    }
    /**
     乘
     */
    func multiplying(num:String) -> String {
        let number1 = NSDecimalNumber(string: self)
        let number2 = NSDecimalNumber(string: num)
        let summation = number1.multiplying(by: number2)
        return summation.stringValue
    }
    /**
     除
     */
    func dividing(num:String) -> String {
        let number1 = NSDecimalNumber(string: self)
        let number2 = NSDecimalNumber(string: num)
        let summation = number1.dividing(by:number2)
        return summation.stringValue
    }
    
    /**
     num 保留几位小数 type 取舍类型
     */
    func numType(num : Int , type : RoundingType) -> String {
        /*
         enum NSRoundingMode : UInt {
         
         case RoundPlain     // Round up on a tie  貌似取整
         case RoundDown      // Always down == truncate  只舍不入
         case RoundUp        // Always up  只入不舍
         case RoundBankers   // on a tie round so last digit is even  貌似四舍五入
         }
         */
        
        // 90.7049 + 0.22 然后四舍五入
        var tp = NSDecimalNumber.RoundingMode.down
        switch type {
        case RoundingType.plain:
            tp = NSDecimalNumber.RoundingMode.plain
        case RoundingType.down:
            tp = NSDecimalNumber.RoundingMode.down
        case RoundingType.up:
            tp = NSDecimalNumber.RoundingMode.up
        case RoundingType.bankers:
            tp = NSDecimalNumber.RoundingMode.bankers
        }
        let roundUp = NSDecimalNumberHandler(roundingMode: tp, scale:Int16(num), raiseOnExactness: false, raiseOnOverflow: false, raiseOnUnderflow: false, raiseOnDivideByZero: true)
        
        let discount = NSDecimalNumber(string: self)
        let subtotal = NSDecimalNumber(string: "0")
        // 加 保留 2 位小数
        let total = subtotal.adding(discount, withBehavior: roundUp).stringValue
        //        let flot = Float(total)!
        //        let str = String(format: "%.2f", flot)
        
        var mutstr = String()
        
        if total.contains(".") {
            let float = total.components(separatedBy: ".").last!;
            if float.count == Int(num) {
                mutstr .append(total);
                return mutstr
            } else {
                mutstr.append(total)
                let all = num - float.count
                for _ in 1...all {
                    mutstr += "0"
                }
                return mutstr
            }
        } else {
            mutstr.append(total + ".")
            if num == 0 {
            } else {
                for _ in 1...num {
                    mutstr += "0"
                }
            }
            return mutstr
        }
        // 加 保留 2 位小数
    }
}
