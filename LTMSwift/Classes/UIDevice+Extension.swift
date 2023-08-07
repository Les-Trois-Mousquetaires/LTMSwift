//
//  UIDevice+Extension.swift
//  LTMSwift
//
//  Created by zsn on 2023/8/7.
//

import Foundation

public extension UIDevice {
    /// 是否是刘海屏
    var isBangScreen: Bool {
        if #available(iOS 11.0, *){
            guard let window = UIApplication.shared.delegate?.window, let unwrapedWindow = window else {
                return false
            }
            if unwrapedWindow.safeAreaInsets.left > 0 || unwrapedWindow.safeAreaInsets.bottom > 0 {
                return true
            }
        }
        
        return false
    }
    
    /// 顶部高度
    var topHeight: CGFloat {
        if #available(iOS 13.0, *) {
            let scene = UIApplication.shared.connectedScenes.first
            guard let windowScene = scene as? UIWindowScene else { return 0 }
            guard let window = windowScene.windows.first else { return 0 }
            return window.safeAreaInsets.top
        }
        if #available(iOS 11.0, *) {
            guard let window = UIApplication.shared.windows.first else { return 0 }
            return window.safeAreaInsets.top
        }
        return 0
    }
    
    /// 底部高度
    var bottomHeight: CGFloat {
        if #available(iOS 13.0, *) {
            let scene = UIApplication.shared.connectedScenes.first
            guard let windowScene = scene as? UIWindowScene else { return 0 }
            guard let window = windowScene.windows.first else { return 0 }
            return window.safeAreaInsets.bottom
        }
        if #available(iOS 11.0, *) {
            guard let window = UIApplication.shared.windows.first else { return 0 }
            return window.safeAreaInsets.bottom
        }
        return 0
    }
    
    /// 顶部状态栏高度
    var statusBarHeight: CGFloat {
        if #available(iOS 13.0, *) {
            let scene = UIApplication.shared.connectedScenes.first
            guard let windowScene = scene as? UIWindowScene else { return 0 }
            guard let statusBarManager = windowScene.statusBarManager else { return 0 }
            return statusBarManager.statusBarFrame.height
        } else {
            return UIApplication.shared.statusBarFrame.height
        }
    }
    
    /// 导航栏高度
    var navBarHeight: CGFloat {
        return 44
    }
    
    /// 状态栏+导航栏的高度
    var navStatusBarHeight: CGFloat {
        return self.statusBarHeight + self.navBarHeight
    }
    
    /// 底部导航栏高度
    var bottomBarHeight: CGFloat {
        return 49
    }
    
    /// 底部导航栏高度
    var bottomNavBarHeight: CGFloat {
        return self.bottomBarHeight + self.bottomHeight
    }
    
}
