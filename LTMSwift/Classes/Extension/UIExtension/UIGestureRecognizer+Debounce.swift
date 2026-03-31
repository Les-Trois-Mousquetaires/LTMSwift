//
//  UIGestureRecognizer+Debounce.swift
//
//  2026/3/27.
//

import UIKit
import ObjectiveC.runtime

private var ltmTapGestureProxyListKey: UInt8 = 0

private final class LTMDebouncedTapGestureProxy: NSObject {
    weak var target: AnyObject?
    weak var sourceView: UIView?
    let action: Selector
    let interval: TimeInterval
    var lastActionTime: TimeInterval = 0

    init(target: AnyObject, action: Selector, sourceView: UIView, interval: TimeInterval) {
        self.target = target
        self.action = action
        self.sourceView = sourceView
        self.interval = interval
        super.init()
    }

    @objc func handleTap() {
        let now = Date().timeIntervalSince1970
        if interval > 0, now - lastActionTime < interval {
            return
        }
        lastActionTime = now

        guard let target else { return }
        UIApplication.shared.sendAction(action, to: target, from: sourceView, for: nil)
    }
}

public extension UIView {
    /**
     为 UIView 增加一个带防抖的点击手势。

     - parameter interval 防抖间隔，单位秒，默认 1 秒。
     - parameter target 事件接收对象。
     - parameter action 事件方法。
     - returns: 创建并已添加到当前视图的 UITapGestureRecognizer。
     */
    @discardableResult
    func addDebouncedTapGesture(interval: TimeInterval = 1.0, target: AnyObject, action: Selector) -> UITapGestureRecognizer {
        isUserInteractionEnabled = true

        let proxy = LTMDebouncedTapGestureProxy(
            target: target,
            action: action,
            sourceView: self,
            interval: interval
        )

        var proxies = objc_getAssociatedObject(self, &ltmTapGestureProxyListKey) as? [LTMDebouncedTapGestureProxy] ?? []
        proxies.append(proxy)
        objc_setAssociatedObject(
            self,
            &ltmTapGestureProxyListKey,
            proxies,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )

        let gesture = UITapGestureRecognizer(target: proxy, action: #selector(LTMDebouncedTapGestureProxy.handleTap))
        addGestureRecognizer(gesture)
        return gesture
    }
}
