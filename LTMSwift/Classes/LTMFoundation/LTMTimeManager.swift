//
//  LTMTimeManager.swift
//  Pods
//
//  Created by 柯南 on 2020/8/3.
//

import Foundation
public class LTMTimeManager: NSObject {
    /**
     今天开始到现在时间
     - parameter dateFormat 时间格式
     
     - returns: 返回开始和结束时间及相应时间戳
     */
    class func todayStartEndTime(dateFormat: String) -> (startDate: (String, String), endDate: (String, String)) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat
        let nowTimeStr = dateFormatter.string(from: Date())
        let nowTimeDate = dateFormatter.date(from: nowTimeStr)
        
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: nowTimeDate!)
        let startDate = calendar.date(from: dateComponents)
        let startDateStr = dateFormatter.string(from: startDate!)
        
        return ((startDateStr,startDateStr.dateStringToMillisecondTimeStamp(dateFormat: dateFormat)),
                (nowTimeStr,nowTimeStr.dateStringToMillisecondTimeStamp(dateFormat: dateFormat)))
    }
    
    /**
     计算本周开始到现在时间
     - parameter dateFormat 时间格式
     
     - returns: 返回开始和结束时间及相应时间戳
     */
    class func weekStartEndTime(dateFormat: String) -> (startDate: (String, String), endDate: (String, String)) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat
        let nowTimeStr = dateFormatter.string(from: Date())
        let nowTimeDate = dateFormatter.date(from: nowTimeStr)
        
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day, .weekday], from: nowTimeDate!)
        let todayWeekDay = dateComponents.weekday
        let todayNum = dateComponents.day
        
        var firstDiff: Int
        if (todayWeekDay == 1) {
            firstDiff = -6
        } else {
            firstDiff = calendar.firstWeekday - todayWeekDay! + 1
        }
        
        var firstDayComp = calendar.dateComponents([.year, .month, .day], from: nowTimeDate!)
        firstDayComp.day = todayNum! + firstDiff
        let firstDayOfWeek = calendar.date(from: firstDayComp)
        let firstDay = dateFormatter.string(from: firstDayOfWeek!)
        
        return ((firstDay,firstDay.dateStringToMillisecondTimeStamp(dateFormat: dateFormat)),
                (nowTimeStr,nowTimeStr.dateStringToMillisecondTimeStamp(dateFormat: dateFormat)))
    }
    
    /**
     本月时间
     - parameter dateFormat 时间格式
     
     - returns: 返回开始和结束时间及相应时间戳
     */
    class func monthStartEndTime(dateFormat: String) -> (startDate: (String, String), endDate: (String, String)) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat
        let nowTimeStr = dateFormatter.string(from: Date())
        let nowTimeDate = dateFormatter.date(from: nowTimeStr)
        
        let calendar = Calendar.current
        var firstDayComp = calendar.dateComponents([.year, .month, .day], from: nowTimeDate!)
        firstDayComp.day = 1
        let firstDayOfWeek = calendar.date(from: firstDayComp)
        let firstDay = dateFormatter.string(from: firstDayOfWeek!)
        
        return ((firstDay,firstDay.dateStringToMillisecondTimeStamp(dateFormat: dateFormat)),
                (nowTimeStr,nowTimeStr.dateStringToMillisecondTimeStamp(dateFormat: dateFormat)))
    }
        
    /**
     本年时间
     - parameter dateFormat 时间格式
     
     - returns: 返回开始和结束时间及相应时间戳
     */
    class func yearStartEndTime(dateFormat: String) -> (startDate: (String, String), endDate: (String, String)) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat
        let nowTimeStr = dateFormatter.string(from: Date())
        let nowTimeDate = dateFormatter.date(from: nowTimeStr)
        
        let calendar = Calendar.current
        var firstDayComp = calendar.dateComponents([.year, .month, .day], from: nowTimeDate!)
        firstDayComp.month = 1
        firstDayComp.day = 1
        let firstDayOfWeek = calendar.date(from: firstDayComp)
        let firstDay = dateFormatter.string(from: firstDayOfWeek!)
        
        return ((firstDay,firstDay.dateStringToMillisecondTimeStamp(dateFormat: dateFormat)),
                (nowTimeStr,nowTimeStr.dateStringToMillisecondTimeStamp(dateFormat: dateFormat)))
    }
        
    /**
     获取今天所在的周一和周日
     - parameter dateFormat 时间格式
     
     - returns: 返回开始和结束时间及相应时间戳
     */
    class func getWeekTime(dateFormat: String) -> (String, String) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat
        let today = dateFormatter.string(from: Date())
        
        let nowDate = dateFormatter.date(from: today)
        let calendar = Calendar.current
        let comp = calendar.dateComponents([.year, .month, .day, .weekday], from: nowDate!)
        
        let weekDay = comp.weekday
        let day = comp.day
        
        var firstDiff: Int
        var lastDiff: Int
        if (weekDay == 1) {
            firstDiff = -6
            lastDiff = 0
        } else {
            firstDiff = calendar.firstWeekday - weekDay! + 1
            lastDiff = 8 - weekDay!
        }
        
        var firstDayComp = calendar.dateComponents([.year, .month, .day], from: nowDate!)
        firstDayComp.day = day! + firstDiff
        let firstDayOfWeek = calendar.date(from: firstDayComp)
        var lastDayComp = calendar.dateComponents([.year, .month, .day], from: nowDate!)
        lastDayComp.day = day! + lastDiff
        let lastDayOfWeek = calendar.date(from: lastDayComp)
        
        let firstDay = dateFormatter.string(from: firstDayOfWeek!)
        let lastDay = dateFormatter.string(from: lastDayOfWeek!)
        
        return (firstDay, lastDay)
    }
}
