//
//  String+Extension.swift
//  LTMSwift
//
//  Created by 柯南 on 2022/11/29.
//

import Foundation
import UIKit

//MARK: - NSString
public extension String{
    /// 字符串布尔值
    var boolValue: Bool{
        return NSString(string: self).boolValue
    }
    
    /// 字符串Int32值
    var intValue: Int32{
        return NSString(string: self).intValue
    }
    
    /// 字符串Int值
    var integerValue: Int{
        return NSString(string: self).integerValue
    }
    
    /// 字符串double值
    var doubleValue: Double{
        return NSString(string: self).doubleValue
    }
    
    /// 字符串float值
    var floatValue: Float{
        return NSString(string: self).floatValue
    }
    
    /// 计算自身Range
    var selfRange: NSRange{
        return self.range(of: self)
    }
    
    /// 计算Range
    func range(of: String) -> NSRange{
        return (self as NSString).range(of: of)
    }
}

public extension String {
    /// 字符串前加空格
    var insertNullAtFirst: String {
        return " " + self
    }
    
    /// 字符串删除空格
    var replacingSpace: String {
        return self.replacingOccurrences(of: " ", with: "")
    }
    
    /**
     小数位展示使用，带逗号
     
     - parameter digit 小数位数, 默认四舍五入
     */
    func decimalDigit(_ digit: Int) -> String{
        return NSDecimalNumber(string: self).decimalDigit(digit)
    }
    
    /**
     小数位给后台传递
     
     - parameter digit 小数位数, 默认四舍五入
     */
    func decimalDigitParam(_ digit: Int) -> String{
        return NSDecimalNumber(string: self).decimalDigitParam(digit)
    }
}

//MARK: - 字符串操作
public extension String{
    //从0索引处开始查找是否包含指定的字符串，返回Int类型的索引
    //返回第一次出现的指定子字符串在此字符串中的索引
    func findFirst(_ sub:String) -> Int {
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
    func findLast(_ sub:String) -> Int {
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
     修改某段文字字体和颜色
     */
    func changeFontColor(subString: String, font: UIFont, textColor: UIColor)-> NSMutableAttributedString {
        let range = (self as NSString).range(of: subString)
        let attStr = NSMutableAttributedString.init(string: self)
        attStr.addAttributes([NSAttributedString.Key.foregroundColor: textColor, NSAttributedString.Key.font: font], range: range)
        
        return attStr
    }
}

//MARK: - 字符串工具
public extension String{
    /// 手机号 3*4格式
    var phoneNum3_4: String {
        if self.count < 8 {
            return self
        }
        let start = self.subString(to: 3)
        let end = self.subString(from: self.count - 4)
        
        return "\(start)****\(end)"
    }
    
    /// 格式化展示电话
    var telFormat: String {
        if self.isPhoneNumber {
            let start = self.subString(to: 3)
            let center = self.subString(from: 3, to: 6)
            let end = self.subString(from: self.count - 4)
            
            return "\(start) \(center) \(end)"
        }else if self.is400Tel {
            return self.tel400Show
        }else if self.isFixedLineTel {
            return self.fixedLineTelShow
        }

        return self
    }
    
    /// 手机号转3 4 4空格格式
    var phoneNum344: String {
        if self.count != 11 {
            return self
        }
        let start = self.subString(to: 3)
        let center = self.subString(from: 3, to: 6)
        let end = self.subString(from: self.count - 4)
        
        return "\(start) \(center) \(end)"
    }
    
    /// 隐藏身份证中间内容
    var idCard3_4: String {
        if (self.count < 7){
            return self
        }
        
        return self.subString(to: 3) + "********" + self.subString(from: self.count - 4)
    }
    
    /// 身份证号转6 8 4空格格式
    var idCard684: String {
        if self.count != 18 {
            return self
        }
        let start = self.subString(to: 6)
        let center = self.subString(from: 6, to: 14)
        let end = self.subString(from: self.count - 4)
        
        return "\(start) \(center) \(end)"
    }
    
    /// 隐藏银行卡中间内容
    var bankCard4_4: String {
        if (self.count < 9){
            return self
        }
        
        return self.subString(to: 4) + " **** **** " + self.subString(from: self.count - 4)
    }
    
    /// 卡号转4位+空格格式
    var bankCard444: String {
        if (self.count > 0){
            var cardNo = self.replacingSpace
            if cardNo.count > 4 {
                let index = cardNo.index(cardNo.startIndex, offsetBy: 4)
                cardNo.insert(" ", at: index)
            }
            if cardNo.count > 9 {
                let index = cardNo.index(cardNo.startIndex, offsetBy: 9)
                cardNo.insert(" ", at: index)
            }
            if cardNo.count > 14 {
                let index = cardNo.index(cardNo.startIndex, offsetBy: 14)
                cardNo.insert(" ", at: index)
            }
            if cardNo.count > 19 {
                let index = cardNo.index(cardNo.startIndex, offsetBy: 19)
                cardNo.insert(" ", at: index)
            }
            return cardNo
        } else {
            return self
        }
    }
    
    /// base64编码字符串生成图片
    var base64Image: UIImage? {
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
    
    /// 字符串汉字转拼音
    var pinYin: String {
        //转化为可变字符串
        let mString = NSMutableString(string: self)
        //转化为带声调的拼音
        CFStringTransform(mString, nil, kCFStringTransformToLatin, false)
        //转化为不带声调
        CFStringTransform(mString, nil, kCFStringTransformStripDiacritics, false)
        //转化为不可变字符串
        let string = NSString(string: mString)
        //去除字符串之间的空格
        return string.replacingOccurrences(of: " ", with: "")
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

//MARK: - 正则及校验
public extension String {
    /// 是否是固定电话
    var isFixedLineTel: Bool {
        let regex = "^0(10|2[0-5789]|\\d{3})\\d{7,8}$"
        return self.isMatch(regex)
    }
    
    /// 固定电话
    var fixedLineTelShow: String {
        if self.isFixedLineTel {
            let regex = "^0(10|2[0-5789])\\d{7,8}$"
            if self.isMatch(regex){
                return self.subString(to: 3) + "-" + self.subString(from: 3)
            }else{
                return self.subString(to: 4) + "-" + self.subString(from: 4)
            }
        }
        
        return self
    }
    
    /// 是否是400电话
    var is400Tel: Bool {
        let regex = "^400[0-9]{7}$"
        return self.isMatch(regex)
    }
    
    /// 固定电话
    var tel400Show: String {
        if self.is400Tel {
            var result: NSMutableString = NSMutableString(string: self)
            if self.count > 3 {
                result.insert("-", at: 3)
            }
            if self.count > 7 {
                result.insert("-", at: 7)
            }
            return result as String
        }
        
        return self
    }
    
    /// 是否是手机号
    var isPhoneNumber: Bool {
        let regex = "^1[0-9]{10}$"
        
        return self.isMatch(regex)
    }
        
    /// 身份证真伪校验
    var idCardNoCheck: Bool{
        if self.replacingSpace.count != 18 {
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
        
    /// 正则
    func isMatch(_ regex: String ) -> Bool {
        let predicate = NSPredicate(format: "SELF MATCHES %@", regex)
        let result: Bool = predicate.evaluate(with: self)
        
        return result
    }
}

//MARK: - 字符串计算高度、宽度
public extension String{
    /**
     计算文本高度
     
     - parameter textFont 文本字体
     - parameter width 文本宽度
     */
    func getHeight(textFont: UIFont, width: CGFloat) -> CGFloat{
        return self.boundingRect(with: CGSize(width: width, height: CGFloat(MAXFLOAT)), options: .usesLineFragmentOrigin, attributes: [.font: textFont], context: nil).size.height
    }
    
    /**
     计算文本高度
     
     - parameter textFont 文本字体
     - parameter height 文本高度
     */
    func getWidth(textFont: UIFont, height: CGFloat) -> CGFloat{
        return self.boundingRect(with: CGSize(width: CGFloat(MAXFLOAT), height: height), options: .usesLineFragmentOrigin, attributes: [.font: textFont], context: nil).size.width
    }
}
