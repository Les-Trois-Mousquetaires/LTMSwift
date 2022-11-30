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
    public func secondTimestamp(dateFormat: String!) -> (String, String){
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
    public func msecondTimestamp(dateFormat: String!) -> (String, String){
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat
        let dateStr = dateFormatter.string(from: self)
        let timeInterval: TimeInterval = self.timeIntervalSince1970
        let timeStamp = CLongLong(round(timeInterval*1000))
        
        return ("\(dateStr)","\(timeStamp)")
    }
}
