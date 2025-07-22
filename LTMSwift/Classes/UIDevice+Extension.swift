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

public extension UIDevice {
    
    func isSimulator() -> Bool {
#if targetEnvironment(simulator)
        return true
#else
        return false
#endif
    }
    
     var detailedModel: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let mirror = Mirror(reflecting: systemInfo.machine)
        return mirror.children.compactMap {
            guard let value = $0.value as? Int8, value != 0 else { return nil }
            return String(UnicodeScalar(UInt8(value)))
        }.joined()
    }
    
     var sizeModel: (size: String, model: String) {
        if UIDevice.current.isSimulator() {
            return ("Simulator", "Simulator")
        }
        let deviceMap: [String: (size: String, model: String)] = [
            "iPhone1,1": ("3.5", "iPhone (1st)"),
            "iPhone1,2": ("3.5", "iPhone 3G"),
            "iPhone2,1": ("3.5", "iPhone 3GS"),
            "iPhone3,1": ("3.5", "iPhone 4"),
            "iPhone3,3": ("3.5", "iPhone 4"),
            "iPhone4,1": ("3.5", "iPhone 4S"),
            "iPhone5,1": ("4.0", "iPhone 5"),
            "iPhone5,2": ("4.0", "iPhone 5"),
            "iPhone5,3": ("4.0", "iPhone 5c"),
            "iPhone5,4": ("4.0", "iPhone 5c"),
            "iPhone6,1": ("4.0", "iPhone 5s"),
            "iPhone6,2": ("4.0", "iPhone 5s"),
            "iPhone7,1": ("5.5", "iPhone 6 Plus"),
            "iPhone7,2": ("4.7", "iPhone 6"),
            "iPhone8,1": ("4.7", "iPhone 6s"),
            "iPhone8,2": ("5.5", "iPhone 6s Plus"),
            "iPhone8,4": ("4.0", "iPhone SE (1st generation)"),
            "iPhone9,1": ("4.7", "iPhone 7"),
            "iPhone9,2": ("5.5", "iPhone 7 Plus"),
            "iPhone9,3": ("4.7", "iPhone 7"),
            "iPhone9,4": ("5.5", "iPhone 7 Plus"),
            "iPhone10,1": ("4.7", "iPhone 8"),
            "iPhone10,2": ("5.5", "iPhone 8 Plus"),
            "iPhone10,3": ("5.8", "iPhone X"),
            "iPhone10,4": ("4.7", "iPhone 8"),
            "iPhone10,5": ("5.5", "iPhone 8 Plus"),
            "iPhone10,6": ("5.8", "iPhone X"),
            "iPhone11,2": ("5.8", "iPhone XS"),
            "iPhone11,4": ("6.5", "iPhone XS Max"),
            "iPhone11,6": ("6.5", "iPhone XS Max"),
            "iPhone11,8": ("6.1", "iPhone XR"),
            "iPhone12,1": ("6.1", "iPhone 11"),
            "iPhone12,3": ("5.8", "iPhone 11 Pro"),
            "iPhone12,5": ("6.5", "iPhone 11 Pro Max"),
            "iPhone12,8": ("4.7", "iPhone SE (2nd generation)"),
            "iPhone13,1": ("5.4", "iPhone 12 mini"),
            "iPhone13,2": ("6.1", "iPhone 12"),
            "iPhone13,3": ("6.1", "iPhone 12 Pro"),
            "iPhone13,4": ("6.7", "iPhone 12 Pro Max"),
            "iPhone14,2": ("6.1", "iPhone 13 Pro"),
            "iPhone14,3": ("6.7", "iPhone 13 Pro Max"),
            "iPhone14,4": ("5.4", "iPhone 13 mini"),
            "iPhone14,5": ("6.1", "iPhone 13"),
            "iPhone14,6": ("4.7", "iPhone SE (3rd generation)"),
            "iPhone14,7": ("6.1", "iPhone 14"),
            "iPhone14,8": ("6.7", "iPhone 14 Plus"),
            "iPhone15,2": ("6.1", "iPhone 14 Pro"),
            "iPhone15,3": ("6.7", "iPhone 14 Pro Max"),
            "iPhone15,4": ("6.1", "iPhone 15"),
            "iPhone15,5": ("6.7", "iPhone 15 Plus"),
            "iPhone16,1": ("6.1", "iPhone 15 Pro"),
            "iPhone16,2": ("6.7", "iPhone 15 Pro Max"),
            "iPhone17,1": ("6.1", "iPhone 16"),
            "iPhone17,3": ("6.3", "iPhone 16 Pro"),
            "iPhone17,2": ("6.7", "iPhone 16 Plus"),
            "iPhone17,4": ("6.9", "iPhone 16 Pro Max"),
            "iPhone17,5": ("6.1", "iPhone SE (4th generation)")
        ]
        print("detailedModel",self.detailedModel)
        return deviceMap[self.detailedModel] ?? ("", "")
    }
    
    /// 是否越狱
    func isJailBreak() -> Bool {
#if targetEnvironment(simulator)
        return false
#else
        let files = [
            "/private/var/lib/apt",
            "/Applications/Cydia.app",
            "/Applications/RockApp.app",
            "/Applications/Icy.app",
            "/Applications/WinterBoard.app",
            "/Applications/SBSetttings.app",
            "/Applications/blackra1n.app",
            "/Applications/IntelliScreen.app",
            "/Applications/Snoop-itConfig.app",
            "/bin/sh",
            "/usr/libexec/sftp-server",
            "/usr/libexec/ssh-keysign /Library/MobileSubstrate/MobileSubstrate.dylib",
            "/bin/bash",
            "/usr/sbin/sshd",
            "/etc/apt /System/Library/LaunchDaemons/com.saurik.Cydia.Startup.plist",
            "/System/Library/LaunchDaemons/com.ikey.bbot.plist",
            "/Library/MobileSubstrate/DynamicLibraries/LiveClock.plist",
            "/Library/MobileSubstrate/DynamicLibraries/Veency.plist"
        ]
        return files.contains(where: {
            return FileManager.default.fileExists(atPath: $0)
        })
#endif
    }
}
