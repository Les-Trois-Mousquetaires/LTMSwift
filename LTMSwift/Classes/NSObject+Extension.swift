//
//  NSObject+Extension.swift
//  LTMSwift
//
//  Created by 柯南 on 2022/11/30.
//

import Foundation
public extension NSObject {
    // 方法交换
    static func ltm_swizzleMethod(_ cls: AnyClass, originalSelector: Selector, swizzleSelector: Selector){
        let originalMethod = class_getInstanceMethod(cls, originalSelector)!
        let swizzledMethod = class_getInstanceMethod(cls, swizzleSelector)!
        let didAddMethod = class_addMethod(cls,
                                           originalSelector,
                                           method_getImplementation(swizzledMethod),
                                           method_getTypeEncoding(swizzledMethod))
        if didAddMethod {
            class_replaceMethod(cls,
                                swizzleSelector,
                                method_getImplementation(originalMethod),
                                method_getTypeEncoding(originalMethod))
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
    }
    
    /**
     系统拨打电话、固定电话
     
     - parameter phone 电话号码
     */
    func callPhone(_ phone: String) {
        var phoneStr = phone
        /// 小于固话长度
        if phone.count < 7{
            return
        }
        if phoneStr.count > 11 {
            phoneStr = phoneStr.deleteNullString()
        }
        // 在cell上 保证丝滑....
        DispatchQueue.main.async {
            let phoneUrlStr = "telprompt://" + phoneStr
            if UIApplication.shared.canOpenURL(URL(string: phoneUrlStr)!) {
                UIApplication.shared.open(URL(string: phoneUrlStr)!, options: [:], completionHandler: nil)
            }
        }
    }
}
