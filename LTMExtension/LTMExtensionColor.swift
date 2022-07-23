//
//  LTMExtensionColor.swift
//  LTMSwift
//
//  Created by kenan0620 on 07/29/2020.
//  Copyright (c) 2020 kenan0620. All rights reserved.
//
import UIKit

public extension UIColor{
    /**
     hex颜色值
     
     - parameter hexString 颜色值
     */
    convenience init(hexString: String) {
        self.init(hexString: hexString,alpha: 1)
    }
    
    /**
     hex颜色值带透明度
     
     - parameter hexString 颜色值
     - parameter alpha 透明度
     */
    convenience init(hexString: String, alpha:CGFloat) {
        //删除前后多余的空格换行
        let hexString = hexString.trimmingCharacters(in: .whitespacesAndNewlines)
        //扫描指定字符串的抽象类,然后scanner会按照你的要求从头到尾扫描这个字符串的每个字符
        let scanner = Scanner(string: hexString)
        if hexString.hasPrefix("#") {
            scanner.scanLocation = 1
        }
        var color: UInt32 = 0
        scanner.scanHexInt32(&color)
        let mask = 0x000000FF
        let redValue = Int(color >> 16) & mask
        let greenValue = Int(color >> 8) & mask
        let blueValue = Int(color) & mask
        
        let red = CGFloat(redValue) / 255.0
        let green = CGFloat(greenValue) / 255.0
        let blue = CGFloat(blueValue) / 255.0
        
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}
