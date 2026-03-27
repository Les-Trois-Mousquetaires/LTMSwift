//
//  UIApplication+Extension.swift
//  LTMSwift
//
//  2026/3/23
//

import UIKit

public extension UIApplication {
    /// 当前激活中的窗口场景（优先 foregroundActive，其次 foregroundInactive）。
    var curWindowScene: UIWindowScene? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first(where: { $0.activationState == .foregroundActive })
        ?? connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first(where: { $0.activationState == .foregroundInactive })
    }

    /// 当前窗口场景中的 keyWindow。
    var curWindow: UIWindow? {
        curWindowScene?
            .windows
            .first(where: \.isKeyWindow) ?? curWindowScene?.windows.first
    }

    /// 当前展示链最顶层的控制器。
    var curTopVC: UIViewController? {
        guard let rootVC = curWindow?.rootViewController else { return nil }
        return Self.curTopVC(from: rootVC)
    }

    /**
     递归查找展示链中最顶层的控制器。

     - parameter vc: 当前起点控制器。
     - returns: 最顶层可见控制器。
     */
    private static func curTopVC(from vc: UIViewController) -> UIViewController {
        if let presentedVC = vc.presentedViewController {
            return curTopVC(from: presentedVC)
        }
        if let navigationVC = vc as? UINavigationController,
           let visibleVC = navigationVC.visibleViewController {
            return curTopVC(from: visibleVC)
        }
        if let tabBarVC = vc as? UITabBarController,
           let selectedVC = tabBarVC.selectedViewController {
            return curTopVC(from: selectedVC)
        }
        if let splitVC = vc as? UISplitViewController,
           let lastVC = splitVC.viewControllers.last {
            return curTopVC(from: lastVC)
        }

        return vc
    }
}
