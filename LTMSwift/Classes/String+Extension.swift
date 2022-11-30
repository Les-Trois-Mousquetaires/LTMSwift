//
//  String+Extension.swift
//  LTMSwift
//
//  Created by 柯南 on 2022/11/29.
//

import Foundation

public extension String{
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
     修改某段文字字体和颜色
     */
    func changeFontColor(subString: String, font: UIFont, textColor: UIColor)-> NSMutableAttributedString {
        let range = (self as NSString).range(of: subString)
        let attStr = NSMutableAttributedString.init(string: self)
        attStr.addAttributes([NSAttributedString.Key.foregroundColor: textColor, NSAttributedString.Key.font: font], range: range)
        
        return attStr
    }
}

public extension String{
    /**
     秒级时间戳转时间
     
     - parameter dateFormat 时间格式
     */
    func secondTimeStampToDate(dateFormat: String!) -> String{
        if self.isEmpty {
            return ""
        }
        
        let interval: TimeInterval = TimeInterval.init(self)!
        if interval > 0  {
            let date = Date(timeIntervalSince1970: interval)
            let dateformatter = DateFormatter()
            dateformatter.dateFormat = dateFormat
            return dateformatter.string(from: date)
        }else {
            return " "
        }
    }
    
    /**
     毫秒级时间戳转时间
     
     - parameter dateFormat 时间格式
     */
    func millisecondTimeStampToDate(dateFormat: String!) -> String{
        if self.isEmpty {
            return ""
        }
        
        let interval: TimeInterval = TimeInterval.init(self)!
        if interval > 0  {
            let date = Date(timeIntervalSince1970: interval/1000)
            let dateformatter = DateFormatter()
            dateformatter.dateFormat = dateFormat
            
            return dateformatter.string(from: date)
        }else {
            return " "
        }
    }
    
    /**
     时间转毫秒级时间戳
     
     - parameter dateFormat 时间格式
     */
    
    func dateStringToMillisecondTimeStamp(dateFormat: String!) -> String {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat
        let date = dateFormatter.date(from: self)
        let dateStamp:TimeInterval = date!.timeIntervalSince1970
        let dateNum:Int = Int(dateStamp)*1000
        
        return String(dateNum)
    }
    
    /**
     时间转秒级时间戳
     
     - parameter dateFormat 时间格式
     */
    func dateStringToSecondTimeStamp(dateFormat: String!) -> String {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat
        let date = dateFormatter.date(from: self)
        let dateStamp:TimeInterval = date!.timeIntervalSince1970
        let dateNum:Int = Int(dateStamp)
        
        return String(dateNum)
    }
}

public extension String{
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

public extension String{
    /**
     base64编码字符串生成图片
     
     - returns 图片
     */
    func base64ToImage() -> UIImage?{
        let base64String = self.replacingOccurrences(of: "data:image/jpg;base64,", with: "")
        //转换尝试判断，有可能返回的数据丢失"=="，如果丢失，swift校验不通过
        var imageData = Data(base64Encoded: base64String, options: .ignoreUnknownCharacters)
        if imageData == nil {
            //如果数据不正确，添加"=="重试
            imageData = Data(base64Encoded: base64String + "==", options: .ignoreUnknownCharacters)
        }
        var image:UIImage?
        if imageData != nil {
            //            print("图片不为空")
            image = UIImage(data: imageData!) ?? UIImage() //转换内容
        } else {
            //            print("图片为空")
        }
        
        return image
    }
}

//MARK: - 手机号字符串
public extension String{
    /**
     手机号转3*4格式
     
     - returns: 处理后的字符串
     */
    func phoneNum3_4() -> String {
        if self.count < 8 {
            return self
        }
        let start = self.subString(to: 3)
        let end = self.subString(from: self.count - 4)
        
        return "\(start)****\(end)"
    }
    
    /**
     手机号转3 4 4空格格式
     
     - returns: 处理后的字符串
     */
    func phoneNum344() -> String {
        if self.count != 11 {
            return self
        }
        let start = self.subString(to: 3)
        let center = self.subString(from: 3, to: 6)
        let end = self.subString(from: self.count - 4)
        
        return "\(start) \(center) \(end)"
    }
}
