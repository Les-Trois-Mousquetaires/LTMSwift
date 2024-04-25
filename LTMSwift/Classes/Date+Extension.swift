//
//  Date+Extension.swift
//  LTMSwift
//
//  Created by 柯南 on 2022/11/29.
//

import Foundation

public extension Date{
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
public extension Date{
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
        let calendar: Calendar = Calendar.current
        var components: DateComponents = DateComponents()
        components.day = days
        
        return calendar.date(byAdding: components, to: self) ?? Date()
    }
    
    /**
     时间前进几小时
     
     - parameter hours  小时数
     - returns 前进后的时间
     */
    func addingHours(_ hours: Int) -> Date{
        let calendar: Calendar = Calendar.current
        var components: DateComponents = DateComponents()
        components.hour = hours
        
        return calendar.date(byAdding: components, to: self) ?? Date()
    }
    
    /**
     时间前进几分钟
     
     - parameter minutes  分钟数
     - returns 前进后的时间
     */
    func addingMinutes(_ minutes: Int) -> Date{
        let calendar: Calendar = Calendar.current
        var components: DateComponents = DateComponents()
        components.minute = minutes
        
        return calendar.date(byAdding: components, to: self) ?? Date()
    }
    
    /**
     时间前进几秒
     
     - parameter seconds  秒数
     - returns 前进后的时间
     */
    func addingSeconds(_ seconds: Int) -> Date{
        let calendar: Calendar = Calendar.current
        var components: DateComponents = DateComponents()
        components.second = seconds
        
        return calendar.date(byAdding: components, to: self) ?? Date()
    }
    
    /**
     两个时间相差
     
     - parameter date 目标时间 比自身大
     
     hours 小时 minutes分钟 seconds秒
     */
    func timeDifference(_ date: Date) -> (hours: Int, minutes: Int, seconds: Int) {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute, .second], from: self, to: date)
        
        let hours = components.hour ?? 0
        let minutes = components.minute ?? 0
        let seconds = components.second ?? 0
        
        return (hours, minutes, seconds)
    }
}

//MARK: - 时间展示
public extension Date {
    
    /// 毫秒级时间戳
    var timeStamp: TimeInterval {
        return self.timeIntervalSince1970 * 1000
    }
    
    /// 年
    var year: Int {
        return Calendar.current.component(Calendar.Component.year, from: self)
    }
    
    /// 月
    var month: Int {
        return Calendar.current.component(Calendar.Component.month, from: self)
    }
    
    /// 日
    var day: Int {
        return Calendar.current.component(Calendar.Component.day, from: self)
    }
    
    /// 时
    var hour: Int {
        return Calendar.current.component(Calendar.Component.hour, from: self)
    }
    
    /// 分
    var minute: Int {
        return Calendar.current.component(Calendar.Component.minute, from: self)
    }
    
    /// 秒
    var second: Int {
        return Calendar.current.component(Calendar.Component.second, from: self)
    }
    
    /// 纳秒
    var nanosecond: Int {
        return Calendar.current.component(Calendar.Component.nanosecond, from: self)
    }
    
    /// 当月天数
    var days: Int{
       return Calendar.current.range(of: Calendar.Component.day, in: Calendar.Component.month, for: self)!.count
    }
    
    /// 星期几
    var weekday: Int{
       return Calendar.current.component(Calendar.Component.weekday, from: self)
    }
    
    /// 工作日的顺序
    var weekdayOrdinal: Int{
       return Calendar.current.component(Calendar.Component.weekdayOrdinal, from: self)
    }
    
    /// 月中的第几周
    var weekOfMonth: Int{
       return Calendar.current.component(Calendar.Component.weekOfMonth, from: self)
    }
    
    /// 年中的第几周
    var weekOfYear: Int{
      return Calendar.current.component(Calendar.Component.weekOfYear, from: self)
    }
    
    /// WeekOfYear component (1~53)
    var yearForWeekOfYear: Int{
        return Calendar.current.component(Calendar.Component.yearForWeekOfYear, from: self)
    }
    
    /// 季度
    var quarter: Int{
        return Calendar.current.component(Calendar.Component.quarter, from: self)
    }
    
    /// 闰年
    var isLeapYear: Bool{
        return (self.year % 400 == 0) || (self.year % 100 != 0 && self.year % 4 == 0)
    }
    
    /// 闰月
    var leapMonth: Bool{
       return Calendar.current.dateComponents([.quarter], from: self).isLeapMonth ?? false
    }
    
    /// 是否在未来
    var isInFuture: Bool {
        return self > Date()
    }
    
    /// 是否在过去
    var isInPast: Bool {
        return self < Date()
    }
    
    /// 是否在本天
    var isToday: Bool {
        if (fabs(self.timeIntervalSinceNow) >= 24 * 60 * 60 ){
            return false
        }
        return self.day == Date().day && self.month == Date().month && self.year == Date().year
    }
    
    /// 是否在本月
    var isInMonth: Bool {
        return self.month == Date().month && self.year == Date().year
    }
    
    
    /// 当天开始时间  0:0:0:0
    var startDate: Date {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = self.year
        components.month = self.month
        components.day = self.day
        
        return calendar.date(from: components) ?? Date()
    }
    
    /// 当天结束时间 23:59:59秒
    var endDate: Date {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = self.year
        components.month = self.month
        components.day = self.day
        components.hour = 23
        components.minute = 59
        components.second = 59
        
        return calendar.date(from: components) ?? Date()
    }
    
    /// 本周星期一
    var weekMonday: Date {
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        var components = DateComponents()
        components.year = self.year
        components.month = self.month
        var countDays: Int = 0
        if(calendar.firstWeekday > self.weekday){
            countDays = 7 + (self.weekday - calendar.firstWeekday)
        }else{
            countDays = self.weekday - calendar.firstWeekday
        }
        components.day = self.day - countDays
        
        return calendar.date(from: components)!
    }
    
    /// 当月1号
    var monthDay: Date {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = self.year
        components.month = self.month
        components.day = 1
        
        return calendar.date(from: components) ?? Date()
    }
    
    /// 月末 本月最后一天
    var monthLastDay: Date {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = self.year
        components.month = self.month
        components.day = self.days
        
        return calendar.date(from: components) ?? Date()
    }
    
    //获得当前月份第一天星期几
    var weekdayForFirstday: Int {
        var calendar = Calendar.current
        calendar.firstWeekday = 1
        var comp = calendar.dateComponents([.year, .month, .day], from: self)
        comp.day = 1
        let firstDayInMonth = calendar.date(from: comp)!
        let weekday = calendar.ordinality(of: Calendar.Component.weekday, in: Calendar.Component.weekOfMonth, for: firstDayInMonth)
        return weekday! - 1
    }
}

//MARK: - 时间展示处理
public extension String{
    
    /**
     字符串转时间
     
     - returns 时间
     */
    func date(format: String = "yyyy-MM-dd") -> Date{
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        
        return dateFormatter.date(from:self) ?? Date()
    }
    
    /// 时间戳转时间
    var date: Date{
        if self.isEmpty {
            return Date()
        }
        
        let interval: TimeInterval = TimeInterval.init(self)!
        if (self.count == 13 && interval > 0){
            return Date(timeIntervalSince1970: interval/1000)
        }else if (self.count == 10 && interval > 0){
            return Date(timeIntervalSince1970: interval)
        }
        
        return Date()
    }
}
