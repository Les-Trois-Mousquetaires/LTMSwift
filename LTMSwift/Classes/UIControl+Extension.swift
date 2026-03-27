//
//  UIControl+Extension.swift
//
//  2026/3/27.
//

import UIKit
import ObjectiveC.runtime

private var ltmControlDebounceIntervalKey: UInt8 = 0
private var ltmControlDebounceLastActionTimeKey: UInt8 = 0

public extension UIControl {
    /**
     开启 UIControl 全局防重复点击。
     只会 swizzle 一次，后续重复调用不会重复交换实现。
     */
    static func enableGlobalDebounce() {
        _ = swizzleOnce
    }

    /// 防重复点击间隔（秒）。默认 UIButton 为 1，其他 UIControl 为 0。
    @IBInspectable
    var ltmDebounceInterval: TimeInterval {
        get {
            if let value = objc_getAssociatedObject(self, &ltmControlDebounceIntervalKey) as? TimeInterval {
                return value
            }
            return self is UIButton ? 1.0 : 0.0
        }
        set {
            objc_setAssociatedObject(
                self,
                &ltmControlDebounceIntervalKey,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }

    var ltmDebounceLastActionTime: TimeInterval {
        get {
            (objc_getAssociatedObject(self, &ltmControlDebounceLastActionTimeKey) as? TimeInterval) ?? 0
        }
        set {
            objc_setAssociatedObject(
                self,
                &ltmControlDebounceLastActionTimeKey,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }

    private static let swizzleOnce: Void = {
        let originalSelector = #selector(UIControl.sendAction(_:to:for:))
        let swizzledSelector = #selector(UIControl.ltm_sendAction(_:to:for:))

        guard
            let originalMethod = class_getInstanceMethod(UIControl.self, originalSelector),
            let swizzledMethod = class_getInstanceMethod(UIControl.self, swizzledSelector)
        else {
            return
        }

        method_exchangeImplementations(originalMethod, swizzledMethod)
    }()

    @objc private func ltm_sendAction(_ action: Selector, to target: Any?, for event: UIEvent?) {
        if ltmDebounceInterval > 0 {
            let now = Date().timeIntervalSince1970
            if now - ltmDebounceLastActionTime < ltmDebounceInterval {
                return
            }
            ltmDebounceLastActionTime = now
        }

        ltm_sendAction(action, to: target, for: event)
    }
}
