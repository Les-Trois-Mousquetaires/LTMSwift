//
//  Swizzling.swift
//  LTMSwift
//
//  Created by zsn on 2023/8/7.
//

import Foundation

/// 魔法协议
public protocol MethodSwizzling : AnyObject {
    // 唤醒
    static func awake()
    /**
     swizzling
     
     - parameter forClass 类
     - parameter originalSelector 原始方法
     - parameter swizzledSelector 交换方法
     */
    static func swizzlingForClass(_ forClass: AnyClass, originalSelector: Selector, swizzledSelector: Selector)
}

public extension MethodSwizzling {
    /**
     swizzling
     
     - parameter forClass 类
     - parameter originalSelector 原始方法
     - parameter swizzledSelector 交换方法
     */
    static func swizzlingForClass(_ forClass: AnyClass, originalSelector: Selector, swizzledSelector: Selector){
        let originInstanceMethod = class_getInstanceMethod(forClass, originalSelector)
        let swizzledInstanceMethod = class_getInstanceMethod(forClass, swizzledSelector)
        guard let originMethod = originInstanceMethod, let swizzledMethod = swizzledInstanceMethod else {
            return
        }
        if class_addMethod(forClass, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod)) {
            class_replaceMethod(forClass, swizzledSelector, method_getImplementation(originMethod), method_getTypeEncoding(originMethod))
        }else{
            method_exchangeImplementations(originMethod, swizzledMethod)
        }
    }
}
