//
//  UIApplication+Extension.swift
//  LTMSwift
//
//  Created by 柯南 on 2022/11/30.
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
    
    var curTopViewController: UIViewController? {
        guard let rootViewController = curWindow?.rootViewController else { return nil }
        return Self.curTopViewController(from: rootViewController)
    }
    
    private static func curTopViewController(from viewController: UIViewController) -> UIViewController {
        if let presentedViewController = viewController.presentedViewController {
            return curTopViewController(from: presentedViewController)
        }
        if let navigationController = viewController as? UINavigationController,
           let visibleViewController = navigationController.visibleViewController {
            return curTopViewController(from: visibleViewController)
        }
        if let tabBarController = viewController as? UITabBarController,
           let selectedViewController = tabBarController.selectedViewController {
            return curTopViewController(from: selectedViewController)
        }
        if let splitViewController = viewController as? UISplitViewController,
           let lastViewController = splitViewController.viewControllers.last {
            return curTopViewController(from: lastViewController)
        }
        
        return viewController
    }
}
