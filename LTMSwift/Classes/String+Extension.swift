//
//  String+Extension.swift
//  LTMSwift
//
//  Created by 柯南 on 2022/11/29.
//

import Foundation
import UIKit

public extension String{
    //从0索引处开始查找是否包含指定的字符串，返回Int类型的索引
    //返回第一次出现的指定子字符串在此字符串中的索引
    func findFirst(_ sub:String)->Int {
        var pos = -1
        if let range = range(of:sub, options: .literal ) {
            if !range.isEmpty {
                pos = self.distance(from:startIndex, to:range.lowerBound)
            }
        }
        return pos
    }
    
    //从0索引处开始查找是否包含指定的字符串，返回Int类型的索引
    //返回最后出现的指定子字符串在此字符串中的索引
    func findLast(_ sub:String)->Int {
        var pos = -1
        if let range = range(of:sub, options: .backwards ) {
            if !range.isEmpty {
                pos = self.distance(from:startIndex, to:range.lowerBound)
            }
        }
        return pos
    }
    
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
    @available(*, deprecated, message:"Use Date+Extension timeStampToDate().")
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
    @available(*, deprecated, message:"Use Date+Extension timeStampToDate().")
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
    @available(*, deprecated, message:"Use Date+Extension timestamp().")
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
    @available(*, deprecated, message:"Use Date+Extension timestamp().")
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
    
    /**
     生成二维码图片
     
     - parameter bgColor 二维码背景颜色
     - parameter qrColor 二维码线条颜色
     - returns 图片
     */
    func createQRImage(_ bgColor: UIColor = .white, _ qrColor: UIColor = .black) -> UIImage?{
        let data = self.data(using: .utf8, allowLossyConversion: false)
        // 创建一个二维码的滤镜
        let qrFilter = CIFilter(name: "CIQRCodeGenerator")!
        qrFilter.setDefaults()
        qrFilter.setValue(data, forKey: "inputMessage")
        qrFilter.setValue("H", forKey: "inputCorrectionLevel")
        let qrCIImage = qrFilter.outputImage
        
        // 创建一个颜色滤镜
        let colorFilter = CIFilter(name: "CIFalseColor")!
        colorFilter.setDefaults()
        colorFilter.setValue(qrCIImage, forKey: "inputImage")
        colorFilter.setValue(CIColor(color: qrColor), forKey: "inputColor0")
        colorFilter.setValue(CIColor(color: bgColor), forKey: "inputColor1")
        
        return UIImage(ciImage: colorFilter.outputImage!.transformed(by: CGAffineTransform(scaleX: 10, y: 10)))
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
    
    /// 隐藏身份证中间内容
    func idCard3_4() -> String{
        if (self.count < 7){
            return self
        }
        
        return self.subString(to: 3) + "********" + self.subString(from: self.count - 4)
    }
    
    /// 隐藏银行卡中间内容
    func bankCard4_4() -> String{
        if (self.count < 9){
            return self
        }
        
        return self.subString(to: 4) + " **** **** " + self.subString(from: self.count - 4)
    }
    
    /// 计算Range
    func range(of: String) -> NSRange{
        return (self as NSString).range(of: of)
    }
}

//MARK: - 字符串正则
public extension String{
    /**
     身份证真伪校验
     
     - returns 真假
     */
    func idCardNoCheck() -> Bool{
        if self.replacingOccurrences(of: " ", with: "").count != 18 {
            return false
        }
        let calculateList = [7, 9, 10, 5, 8, 4, 2, 1, 6, 3, 7, 9, 10, 5, 8, 4, 2, 0]
        let checkList = ["1","0","X","9","8","7","6","5","4","3","2",]
        var sum: Int = 0
        for index in 0 ..< 17{
            let curentStr = self.subString(from: index, to: index)
            sum += (Int(curentStr) ?? 0) * calculateList[index]
        }
        let checkIndex = sum % 11
        
        return checkList[checkIndex] == self.subString(from: 17, to: 17)
    }
}

//MARK: - 字符串计算高度、宽度
public extension String{
    /**
     计算文本高度
     
     - parameter string 文本内容
     - parameter textFont 文本字体
     - parameter width 文本宽度
     */
    func stringHeight(textFont: UIFont, width: CGFloat) -> CGFloat{
        return self.boundingRect(with: CGSize(width: width, height: CGFloat(MAXFLOAT)), options: .usesLineFragmentOrigin, attributes: [.font: textFont], context: nil).size.height
    }
    
    /**
     计算文本高度
     
     - parameter string 文本内容
     - parameter textFont 文本字体
     - parameter height 文本高度
     */
    func stringWidth(textFont: UIFont, height: CGFloat) -> CGFloat{
        return self.boundingRect(with: CGSize(width: CGFloat(MAXFLOAT), height: height), options: .usesLineFragmentOrigin, attributes: [.font: textFont], context: nil).size.width
    }
}
