//
//  UIColor+Extension.swift
//  LTMSwift
//
//  Created by 柯南 on 2022/11/29.
//

import Foundation
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
        var normalizedHex = hexString.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if normalizedHex.hasPrefix("#") {
            normalizedHex.removeFirst()
        } else if normalizedHex.hasPrefix("0X") {
            normalizedHex = String(normalizedHex.dropFirst(2))
        }

        if normalizedHex.count == 3 {
            normalizedHex = normalizedHex.map { "\($0)\($0)" }.joined()
        }

        guard normalizedHex.count == 6,
              let color = UInt64(normalizedHex, radix: 16) else {
            self.init(white: 0, alpha: 0)
            return
        }

        let red = CGFloat((color & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((color & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(color & 0x0000FF) / 255.0
        self.init(red: red, green: green, blue: blue, alpha: max(0, min(alpha, 1)))
    }
}
