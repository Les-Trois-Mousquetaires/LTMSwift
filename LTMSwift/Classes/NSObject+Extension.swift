//
//  NSObject+Extension.swift
//  FBSnapshotTestCase
//
//  Created by 柯南 on 2022/11/30.
//

import Foundation
public extension NSObject {
    // 方法交换
    public static func ltm_swizzleMethod(_ cls: AnyClass, originalSelector: Selector, swizzleSelector: Selector){
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
}
