//
//  UIApplication+Extension.swift
//  LTMSwift
//
//  2026/3/23
//

import UIKit

public extension UIApplication {
    var curWindowScene: UIWindowScene? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first(where: { $0.activationState == .foregroundActive })
        ?? connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first(where: { $0.activationState == .foregroundInactive })
    }
    
    var curWindow: UIWindow? {
        curWindowScene?
            .windows
            .first(where: \.isKeyWindow) ?? curWindowScene?.windows.first
    }
    
    var curTopVC: UIViewController? {
        guard let rootVC = curWindow?.rootViewController else { return nil }
        return Self.curTopVC(from: rootVC)
    }
    
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
