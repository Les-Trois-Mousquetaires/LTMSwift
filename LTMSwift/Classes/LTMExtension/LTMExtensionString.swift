//
//  LTMExtensionString.swift
//  ZhiHuiKuangShan
//
//  Created by 柯南 on 2020/7/6.
//  Copyright © 2020 TianRui. All rights reserved.
//

import UIKit

extension String{
    
    /**
     截取到任意位置
     */
    func subString(to: Int) -> String {
        let index: String.Index = self.index(startIndex, offsetBy: to)
        return String(self[..<index])
    }
    
    /**
     从任意位置开始截取
     */
    func subString(from: Int) -> String {
        let index: String.Index = self.index(startIndex, offsetBy: from)
        return String(self[index ..< endIndex])
    }
    
    /**
     从任意位置开始截取到任意位置
     */
    func subString(from: Int, to: Int) -> String {
        let beginIndex = self.index(self.startIndex, offsetBy: from)
        let endIndex = self.index(self.startIndex, offsetBy: to)
        return String(self[beginIndex...endIndex])
    }
    
    /**
     字符串前加空格
     */
    func appendFirstNullString() -> String{
        let mutabString: NSMutableString = NSMutableString()
        
        return mutabString.appending(" \(self)")
    }
    
    /**
     字符串删除空格
     */
    func deleteNullString() -> String{
        let mutabString: NSMutableString = NSMutableString.init(string: self.replacingOccurrences(of: " ", with: ""))
        
        return mutabString as String
    }
    
    /**
     手机号344格式显示
     */
    func phoneNumberFormatString() -> String{
        if self.count < 11 {
            return self
        }
        
        let mutabString: NSMutableString = NSMutableString.init(string: self.replacingOccurrences(of: " ", with: ""))
        if mutabString.length > 3 {
            mutabString.insert(" ", at: 3)
        }
        if mutabString.length > 8 {
            mutabString.insert(" ", at: 8)
        }
        
        return mutabString as String
    }
    
    /**
     修改某段文字字体和颜色
     */
    func changeFontColor(subString: String, font: UIFont, textColor: UIColor)-> NSMutableAttributedString {
        let range = (self as NSString).range(of: subString)
        let attStr = NSMutableAttributedString.init(string: self)
        attStr.addAttributes([NSAttributedString.Key.foregroundColor: textColor, NSAttributedString.Key.font: font], range: range)
        return attStr
    }
    
    /**
     时间戳转时间
     */
    func getDateDayStyleFormatString() ->String{
        
        if self.isEmpty {
            return ""
        }
        
        let interval: TimeInterval = TimeInterval.init(self)!
        if interval > 0  {
            let date = Date(timeIntervalSince1970: interval/1000)
            let dateformatter = DateFormatter()
            dateformatter.dateFormat = "yyyy/MM/dd"
            return dateformatter.string(from: date)
        }else {
            return " "
        }
    }
    
}

extension String{
    /**
     时间戳转时间
     
     */
    static func getDateFormatString(timeStamp:String) ->String{
        
        if timeStamp.isEmpty {
            return ""
        }
        
        let interval: TimeInterval = TimeInterval.init(timeStamp)!
        if interval > 0  {
            let date = Date(timeIntervalSince1970: interval/1000)
            let dateformatter = DateFormatter()
            dateformatter.dateFormat = "yyyy/MM/dd HH:mm:ss"
            return dateformatter.string(from: date)
        }else {
            return " "
        }
    }
    
    /**
     时间戳转时间
     
     */
    static func getDateMinutesFormatString(timeStamp:String) ->String{
        
        if timeStamp.isEmpty {
            return ""
        }
        
        let interval: TimeInterval = TimeInterval.init(timeStamp)!
        if interval > 0  {
            let date = Date(timeIntervalSince1970: interval/1000)
            let dateformatter = DateFormatter()
            dateformatter.dateFormat = "yyyy/MM/dd HH:mm"
            return dateformatter.string(from: date)
        }else {
            return " "
        }
    }
    
    /**
     时间戳转时间 yyyy-MM-dd
     
     */
    static func getDateYMDString(timeStamp:String) ->String{
        
        let interval: TimeInterval = TimeInterval.init(timeStamp)!
        let date = Date(timeIntervalSince1970: interval/1000)
        let dateformatter = DateFormatter()
        dateformatter.dateFormat = "yyyy年MM月dd"
        return dateformatter.string(from: date)
    }
    
    /**
     时间转时间戳
     
     */
    static func stringToTimeStamp(stringTime:String)->String {
        
        let dfmatter = DateFormatter()
        dfmatter.dateFormat="yyyy年MM月dd日"
        let date = dfmatter.date(from: stringTime)
        
        let dateStamp:TimeInterval = date!.timeIntervalSince1970
        
        let dateSt:Int = Int(dateStamp)
        print(dateSt)
        return String(dateSt)
        
    }
    
    static func stringToTimeStamp1000(stringTime:String)->String {
        
        let dfmatter = DateFormatter()
        dfmatter.dateFormat="yyyy年MM月dd日"
        let date = dfmatter.date(from: stringTime)
        
        let dateStamp:TimeInterval = date!.timeIntervalSince1970
        
        let dateSt:Int = Int(dateStamp)*1000
        print(dateSt)
        return String(dateSt)
        
    }
}

extension String{
    
    /**
     字符串转Int
     */
    func LTMStringToInt() -> Int{
        var res : Int = 0
        /// 正数 true 负数 false
        var isPositiveNumber : Bool = true
        /// 索引位置
        var position = 0
        
        //1.去掉空格
        let arr = Array(self)
        while position < arr.count , arr[position] == " "{
            position += 1
        }
        //2.查找正负符号
        if position < arr.count , arr[position] == "-"{
            isPositiveNumber = false
            position += 1
        }else if position < arr.count , arr[position] == "+"{
            isPositiveNumber = true
            position += 1
        }
        //3.获取数字
        while position < arr.count {
            let r = arr[position]
            //判断r 是否为数字
            if r.isNumber{
                res = 10 * res + Int(r.asciiValue!) - Int(Character("0").asciiValue!)
                if isPositiveNumber , res >= Int64.max{
                    return Int(Int64.max)
                }
                if !isPositiveNumber , res > Int64.max{
                    return Int(Int64.min)
                }
            }else{
                break
            }
            position += 1
        }
        
        return isPositiveNumber ? Int(res) : -Int(res)
    }
}

