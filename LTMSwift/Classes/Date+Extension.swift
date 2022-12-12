//
//  Date+Extension.swift
//  LTMSwift
//
//  Created by 柯南 on 2022/11/29.
//

import Foundation

public extension Date{
    /**
     时间格式转换及转秒级时间戳
     
     - parameter dateFormat 时间展示格式
     
     - returns: 转换后时间字符串及时间戳元组
     */
    func secondTimestamp(dateFormat: String!) -> (String, String){
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat
        let dateStr = dateFormatter.string(from: self)
        let timeInterval: TimeInterval = self.timeIntervalSince1970
        let timeStamp = CLongLong(round(timeInterval))
        
        return ("\(dateStr)","\(timeStamp)")
    }
    
    /**
     时间格式转换及转毫秒级时间戳
     
     - parameter dateFormat 时间展示格式
     
     - returns: 转换后时间字符串及时间戳元组
     */
    func msecondTimestamp(dateFormat: String!) -> (String, String){
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat
        let dateStr = dateFormatter.string(from: self)
        let timeInterval: TimeInterval = self.timeIntervalSince1970
        let timeStamp = CLongLong(round(timeInterval*1000))
        
        return ("\(dateStr)","\(timeStamp)")
    }
    
    /**
     时间转字符串
     
     - parameter format 转换时间格式
     */
    func string(_ format: String = "yyyy-MM-dd") -> String{
        let dateFormatter: DateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        
        return dateFormatter.string(from: self)
    }
}

//MARK: - 时间操作
extension Date{
    /**
     时间前进几年
     
     - parameter years  年数
     - returns 前进后的时间
     */
    func addingYears(_ years: Int) -> Date{
        let calendar: Calendar = Calendar.current
        var components: DateComponents = DateComponents()
        components.year = years
        
        return calendar.date(byAdding: components, to: self) ?? Date()
    }
    
    /**
     时间前进几月
     
     - parameter months  月数
     - returns 前进后的时间
     */
    func addingMonths(_ months: Int) -> Date{
        let calendar: Calendar = Calendar.current
        var components: DateComponents = DateComponents()
        components.month = months
        
        return calendar.date(byAdding: components, to: self) ?? Date()
    }
    
    /**
     时间前进几周
     
     - parameter weeks  周数
     - returns 前进后的时间
     */
    func addingWeeks(_ weeks: Int) -> Date{
        let calendar: Calendar = Calendar.current
        var components: DateComponents = DateComponents()
        components.weekOfYear = weeks
        
        return calendar.date(byAdding: components, to: self) ?? Date()
    }
    
    /**
     时间前进几天
     
     - parameter days  天数
     - returns 前进后的时间
     */
    func addingDays(_ days: Int) -> Date{
        return self.addingHours(24 * days)
    }
    
    /**
     时间前进几小时
     
     - parameter hours  小时数
     - returns 前进后的时间
     */
    func addingHours(_ hours: Int) -> Date{
        return self.addingMinutes(60 * hours)
    }
    
    /**
     时间前进几分钟
     
     - parameter minutes  分钟数
     - returns 前进后的时间
     */
    func addingMinutes(_ minutes: Int) -> Date{
        return self.addingSeconds(60 * minutes)
    }
    
    /**
     时间前进几天
     
     - parameter days  天数
     - returns 前进后的时间
     */
    func addingSeconds(_ seconds: Int) -> Date{
        let timeInterval: Double = self.timeIntervalSinceReferenceDate + Double(seconds)
        
        return Date.init(timeIntervalSinceReferenceDate: timeInterval)
    }
}
