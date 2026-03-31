//
//  NSObject+Extension.swift
//  LTMSwift
//
//  Created by 柯南 on 2022/11/30.
//

import Foundation
import UIKit
public extension NSObject {
    // 方法交换
    static func swizzleMethod(_ cls: AnyClass, originalSelector: Selector, swizzleSelector: Selector) {
        ltmSwizzleMethod(cls, originalSelector: originalSelector, swizzledSelector: swizzleSelector)
    }
    
    /**
     系统拨打电话、固定电话
     
     - parameter phone 电话号码
     */
    func callPhone(_ phone: String) {
        let allowedCharacters = CharacterSet(charactersIn: "+0123456789")
        let phoneStr = phone.unicodeScalars.filter { allowedCharacters.contains($0) }.map(String.init).joined()
        /// 小于固话长度
        if phoneStr.count < 7{
            return
        }
        // 在cell上 保证丝滑....
        DispatchQueue.main.async {
            let phoneUrlStr = "tel://" + phoneStr
            guard let phoneUrl = URL(string: phoneUrlStr),
                  UIApplication.shared.canOpenURL(phoneUrl) else {
                return
            }
            UIApplication.shared.open(phoneUrl, options: [:], completionHandler: nil)
        }
    }
}
