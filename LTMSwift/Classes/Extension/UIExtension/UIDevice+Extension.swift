//
//  UIDevice+Extension.swift
//  LTMSwift
//
//  Created by zsn on 2023/8/7.
//

import Foundation
import UIKit

public extension UIDevice {
    /// 是否是刘海屏
    var isBangScreen: Bool {
        guard let window = UIApplication.shared.curWindow else { return false }
        return window.safeAreaInsets.left > 0 || window.safeAreaInsets.bottom > 0
    }
    
    /// 顶部高度
    var topHeight: CGFloat {
        guard let window = UIApplication.shared.curWindow else { return 0 }
        return window.safeAreaInsets.top
    }
    
    /// 底部高度
    var bottomHeight: CGFloat {
        guard let window = UIApplication.shared.curWindow else { return 0 }
        return window.safeAreaInsets.bottom
    }
    
    /// 顶部状态栏高度
    var statusBarHeight: CGFloat {
        guard let statusBarManager = UIApplication.shared.curWindowScene?.statusBarManager else { return 0 }
        return statusBarManager.statusBarFrame.height
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
    
    private static let iPhoneMap: [String: (size: String, model: String, modelEn: String)] = [
        "iPhone1,1": ("3.5", "iPhone (第1代)", "iPhone (1st generation)"),
        "iPhone1,2": ("3.5", "iPhone 3G", "iPhone 3G"),
        "iPhone2,1": ("3.5", "iPhone 3GS", "iPhone 3GS"),
        "iPhone3,1": ("3.5", "iPhone 4", "iPhone 4"),
        "iPhone3,2": ("3.5", "iPhone 4", "iPhone 4"),
        "iPhone3,3": ("3.5", "iPhone 4", "iPhone 4"),
        "iPhone4,1": ("3.5", "iPhone 4s", "iPhone 4s"),
        "iPhone5,1": ("4.0", "iPhone 5", "iPhone 5"),
        "iPhone5,2": ("4.0", "iPhone 5", "iPhone 5"),
        "iPhone5,3": ("4.0", "iPhone 5c", "iPhone 5c"),
        "iPhone5,4": ("4.0", "iPhone 5c", "iPhone 5c"),
        "iPhone6,1": ("4.0", "iPhone 5s", "iPhone 5s"),
        "iPhone6,2": ("4.0", "iPhone 5s", "iPhone 5s"),
        "iPhone7,1": ("5.5", "iPhone 6 Plus", "iPhone 6 Plus"),
        "iPhone7,2": ("4.7", "iPhone 6", "iPhone 6"),
        "iPhone8,1": ("4.7", "iPhone 6s", "iPhone 6s"),
        "iPhone8,2": ("5.5", "iPhone 6s Plus", "iPhone 6s Plus"),
        "iPhone8,4": ("4.0", "iPhone SE (第1代)", "iPhone SE (1st generation)"),
        "iPhone9,1": ("4.7", "iPhone 7", "iPhone 7"),
        "iPhone9,2": ("5.5", "iPhone 7 Plus", "iPhone 7 Plus"),
        "iPhone9,3": ("4.7", "iPhone 7", "iPhone 7"),
        "iPhone9,4": ("5.5", "iPhone 7 Plus", "iPhone 7 Plus"),
        "iPhone10,1": ("4.7", "iPhone 8", "iPhone 8"),
        "iPhone10,2": ("5.5", "iPhone 8 Plus", "iPhone 8 Plus"),
        "iPhone10,3": ("5.8", "iPhone X", "iPhone X"),
        "iPhone10,4": ("4.7", "iPhone 8", "iPhone 8"),
        "iPhone10,5": ("5.5", "iPhone 8 Plus", "iPhone 8 Plus"),
        "iPhone10,6": ("5.8", "iPhone X", "iPhone X"),
        "iPhone11,2": ("5.8", "iPhone XS", "iPhone XS"),
        "iPhone11,4": ("6.5", "iPhone XS Max", "iPhone XS Max"),
        "iPhone11,6": ("6.5", "iPhone XS Max", "iPhone XS Max"),
        "iPhone11,8": ("6.1", "iPhone XR", "iPhone XR"),
        "iPhone12,1": ("6.1", "iPhone 11", "iPhone 11"),
        "iPhone12,3": ("5.8", "iPhone 11 Pro", "iPhone 11 Pro"),
        "iPhone12,5": ("6.5", "iPhone 11 Pro Max", "iPhone 11 Pro Max"),
        "iPhone12,8": ("4.7", "iPhone SE (第2代)", "iPhone SE (2nd generation)"),
        "iPhone13,1": ("5.4", "iPhone 12 mini", "iPhone 12 mini"),
        "iPhone13,2": ("6.1", "iPhone 12", "iPhone 12"),
        "iPhone13,3": ("6.1", "iPhone 12 Pro", "iPhone 12 Pro"),
        "iPhone13,4": ("6.7", "iPhone 12 Pro Max", "iPhone 12 Pro Max"),
        "iPhone14,2": ("6.1", "iPhone 13 Pro", "iPhone 13 Pro"),
        "iPhone14,3": ("6.7", "iPhone 13 Pro Max", "iPhone 13 Pro Max"),
        "iPhone14,4": ("5.4", "iPhone 13 mini", "iPhone 13 mini"),
        "iPhone14,5": ("6.1", "iPhone 13", "iPhone 13"),
        "iPhone14,6": ("4.7", "iPhone SE (第3代)", "iPhone SE (3rd generation)"),
        "iPhone14,7": ("6.1", "iPhone 14", "iPhone 14"),
        "iPhone14,8": ("6.7", "iPhone 14 Plus", "iPhone 14 Plus"),
        "iPhone15,2": ("6.1", "iPhone 14 Pro", "iPhone 14 Pro"),
        "iPhone15,3": ("6.7", "iPhone 14 Pro Max", "iPhone 14 Pro Max"),
        "iPhone15,4": ("6.1", "iPhone 15", "iPhone 15"),
        "iPhone15,5": ("6.7", "iPhone 15 Plus", "iPhone 15 Plus"),
        "iPhone16,1": ("6.1", "iPhone 15 Pro", "iPhone 15 Pro"),
        "iPhone16,2": ("6.7", "iPhone 15 Pro Max", "iPhone 15 Pro Max"),
        "iPhone17,1": ("6.3", "iPhone 16 Pro", "iPhone 16 Pro"),
        "iPhone17,2": ("6.9", "iPhone 16 Pro Max", "iPhone 16 Pro Max"),
        "iPhone17,3": ("6.1", "iPhone 16", "iPhone 16"),
        "iPhone17,4": ("6.7", "iPhone 16 Plus", "iPhone 16 Plus"),
        "iPhone17,5": ("6.1", "iPhone 16e", "iPhone 16e"),
        "iPhone18,1": ("6.3", "iPhone 17 Pro", "iPhone 17 Pro"),
        "iPhone18,2": ("6.9", "iPhone 17 Pro Max", "iPhone 17 Pro Max"),
        "iPhone18,3": ("6.3", "iPhone 17", "iPhone 17"),
        "iPhone18,4": ("6.6", "iPhone Air", "iPhone Air"),
    ]

    private static let iPadMap: [String: (size: String, model: String, modelEn: String)] = [
        "iPad1,1": ("9.7", "iPad (第1代)", "iPad (1st generation)"),
        "iPad2,1": ("9.7", "iPad (第2代)", "iPad (2nd generation)"),
        "iPad2,2": ("9.7", "iPad (第2代)", "iPad (2nd generation)"),
        "iPad2,3": ("9.7", "iPad (第2代)", "iPad (2nd generation)"),
        "iPad2,4": ("9.7", "iPad (第2代)", "iPad (2nd generation)"),
        "iPad2,5": ("7.9", "iPad mini (第1代)", "iPad mini (1st generation)"),
        "iPad2,6": ("7.9", "iPad mini (第1代)", "iPad mini (1st generation)"),
        "iPad2,7": ("7.9", "iPad mini (第1代)", "iPad mini (1st generation)"),
        "iPad3,1": ("9.7", "iPad (第3代)", "iPad (3rd generation)"),
        "iPad3,2": ("9.7", "iPad (第3代)", "iPad (3rd generation)"),
        "iPad3,3": ("9.7", "iPad (第3代)", "iPad (3rd generation)"),
        "iPad3,4": ("9.7", "iPad (第4代)", "iPad (4th generation)"),
        "iPad3,5": ("9.7", "iPad (第4代)", "iPad (4th generation)"),
        "iPad3,6": ("9.7", "iPad (第4代)", "iPad (4th generation)"),
        "iPad3,7": ("9.7", "iPad (第4代)", "iPad (4th generation)"),
        "iPad3,8": ("9.7", "iPad (第4代)", "iPad (4th generation)"),
        "iPad3,9": ("9.7", "iPad (第4代)", "iPad (4th generation)"),
        "iPad4,1": ("9.7", "iPad Air (第1代)", "iPad Air (1st generation)"),
        "iPad4,2": ("9.7", "iPad Air (第1代)", "iPad Air (1st generation)"),
        "iPad4,3": ("9.7", "iPad Air (第1代)", "iPad Air (1st generation)"),
        "iPad4,4": ("7.9", "iPad mini (第2代)", "iPad mini (2nd generation)"),
        "iPad4,5": ("7.9", "iPad mini (第2代)", "iPad mini (2nd generation)"),
        "iPad4,6": ("7.9", "iPad mini (第2代)", "iPad mini (2nd generation)"),
        "iPad4,7": ("7.9", "iPad mini (第3代)", "iPad mini (3rd generation)"),
        "iPad4,8": ("7.9", "iPad mini (第3代)", "iPad mini (3rd generation)"),
        "iPad4,9": ("7.9", "iPad mini (第3代)", "iPad mini (3rd generation)"),
        "iPad5,1": ("7.9", "iPad mini (第4代)", "iPad mini (4th generation)"),
        "iPad5,2": ("7.9", "iPad mini (第4代)", "iPad mini (4th generation)"),
        "iPad5,3": ("9.7", "iPad Air (第2代)", "iPad Air (2nd generation)"),
        "iPad5,4": ("9.7", "iPad Air (第2代)", "iPad Air (2nd generation)"),
        "iPad6,3": ("9.7", "iPad Pro 9.7-inch", "iPad Pro 9.7-inch"),
        "iPad6,4": ("9.7", "iPad Pro 9.7-inch", "iPad Pro 9.7-inch"),
        "iPad6,7": ("12.9", "iPad Pro 12.9-inch (第1代)", "iPad Pro 12.9-inch (1st generation)"),
        "iPad6,8": ("12.9", "iPad Pro 12.9-inch (第1代)", "iPad Pro 12.9-inch (1st generation)"),
        "iPad6,11": ("9.7", "iPad (第5代)", "iPad (5th generation)"),
        "iPad6,12": ("9.7", "iPad (第5代)", "iPad (5th generation)"),
        "iPad7,1": ("12.9", "iPad Pro 12.9-inch (第2代)", "iPad Pro 12.9-inch (2nd generation)"),
        "iPad7,2": ("12.9", "iPad Pro 12.9-inch (第2代)", "iPad Pro 12.9-inch (2nd generation)"),
        "iPad7,3": ("10.5", "iPad Pro 10.5-inch", "iPad Pro 10.5-inch"),
        "iPad7,4": ("10.5", "iPad Pro 10.5-inch", "iPad Pro 10.5-inch"),
        "iPad7,5": ("9.7", "iPad (第6代)", "iPad (6th generation)"),
        "iPad7,6": ("9.7", "iPad (第6代)", "iPad (6th generation)"),
        "iPad7,11": ("10.2", "iPad (第7代)", "iPad (7th generation)"),
        "iPad7,12": ("10.2", "iPad (第7代)", "iPad (7th generation)"),
        "iPad8,1": ("11", "iPad Pro 11-inch (第1代)", "iPad Pro 11-inch (1st generation)"),
        "iPad8,2": ("11", "iPad Pro 11-inch (第1代)", "iPad Pro 11-inch (1st generation)"),
        "iPad8,3": ("11", "iPad Pro 11-inch (第1代)", "iPad Pro 11-inch (1st generation)"),
        "iPad8,4": ("11", "iPad Pro 11-inch (第1代)", "iPad Pro 11-inch (1st generation)"),
        "iPad8,5": ("12.9", "iPad Pro 12.9-inch (第3代)", "iPad Pro 12.9-inch (3rd generation)"),
        "iPad8,6": ("12.9", "iPad Pro 12.9-inch (第3代)", "iPad Pro 12.9-inch (3rd generation)"),
        "iPad8,7": ("12.9", "iPad Pro 12.9-inch (第3代)", "iPad Pro 12.9-inch (3rd generation)"),
        "iPad8,8": ("12.9", "iPad Pro 12.9-inch (第3代)", "iPad Pro 12.9-inch (3rd generation)"),
        "iPad8,9": ("11", "iPad Pro 11-inch (第2代)", "iPad Pro 11-inch (2nd generation)"),
        "iPad8,10": ("11", "iPad Pro 11-inch (第2代)", "iPad Pro 11-inch (2nd generation)"),
        "iPad8,11": ("12.9", "iPad Pro 12.9-inch (第4代)", "iPad Pro 12.9-inch (4th generation)"),
        "iPad8,12": ("12.9", "iPad Pro 12.9-inch (第4代)", "iPad Pro 12.9-inch (4th generation)"),
        "iPad11,1": ("7.9", "iPad mini (第5代)", "iPad mini (5th generation)"),
        "iPad11,2": ("7.9", "iPad mini (第5代)", "iPad mini (5th generation)"),
        "iPad11,3": ("10.5", "iPad Air (第3代)", "iPad Air (3rd generation)"),
        "iPad11,4": ("10.5", "iPad Air (第3代)", "iPad Air (3rd generation)"),
        "iPad11,6": ("10.2", "iPad (第8代)", "iPad (8th generation)"),
        "iPad11,7": ("10.2", "iPad (第8代)", "iPad (8th generation)"),
        "iPad12,1": ("10.2", "iPad (第9代)", "iPad (9th generation)"),
        "iPad12,2": ("10.2", "iPad (第9代)", "iPad (9th generation)"),
        "iPad13,1": ("10.9", "iPad Air (第4代)", "iPad Air (4th generation)"),
        "iPad13,2": ("10.9", "iPad Air (第4代)", "iPad Air (4th generation)"),
        "iPad13,4": ("11", "iPad Pro 11-inch (第3代)", "iPad Pro 11-inch (3rd generation)"),
        "iPad13,5": ("11", "iPad Pro 11-inch (第3代)", "iPad Pro 11-inch (3rd generation)"),
        "iPad13,6": ("11", "iPad Pro 11-inch (第3代)", "iPad Pro 11-inch (3rd generation)"),
        "iPad13,7": ("11", "iPad Pro 11-inch (第3代)", "iPad Pro 11-inch (3rd generation)"),
        "iPad13,8": ("12.9", "iPad Pro 12.9-inch (第5代)", "iPad Pro 12.9-inch (5th generation)"),
        "iPad13,9": ("12.9", "iPad Pro 12.9-inch (第5代)", "iPad Pro 12.9-inch (5th generation)"),
        "iPad13,10": ("12.9", "iPad Pro 12.9-inch (第5代)", "iPad Pro 12.9-inch (5th generation)"),
        "iPad13,11": ("12.9", "iPad Pro 12.9-inch (第5代)", "iPad Pro 12.9-inch (5th generation)"),
        "iPad13,16": ("10.9", "iPad Air (第5代)", "iPad Air (5th generation)"),
        "iPad13,17": ("10.9", "iPad Air (第5代)", "iPad Air (5th generation)"),
        "iPad13,18": ("10.9", "iPad (第10代)", "iPad (10th generation)"),
        "iPad13,19": ("10.9", "iPad (第10代)", "iPad (10th generation)"),
        "iPad14,1": ("8.3", "iPad mini (第6代)", "iPad mini (6th generation)"),
        "iPad14,2": ("8.3", "iPad mini (第6代)", "iPad mini (6th generation)"),
        "iPad14,3": ("11", "iPad Pro 11-inch (第4代)", "iPad Pro 11-inch (4th generation)"),
        "iPad14,4": ("11", "iPad Pro 11-inch (第4代)", "iPad Pro 11-inch (4th generation)"),
        "iPad14,5": ("12.9", "iPad Pro 12.9-inch (第6代)", "iPad Pro 12.9-inch (6th generation)"),
        "iPad14,6": ("12.9", "iPad Pro 12.9-inch (第6代)", "iPad Pro 12.9-inch (6th generation)"),
        "iPad14,8": ("11", "iPad Air 11-inch (M2)", "iPad Air 11-inch (M2)"),
        "iPad14,9": ("11", "iPad Air 11-inch (M2)", "iPad Air 11-inch (M2)"),
        "iPad14,10": ("13", "iPad Air 13-inch (M2)", "iPad Air 13-inch (M2)"),
        "iPad14,11": ("13", "iPad Air 13-inch (M2)", "iPad Air 13-inch (M2)"),
        "iPad16,1": ("8.3", "iPad mini (A17 Pro)", "iPad mini (A17 Pro)"),
        "iPad16,2": ("8.3", "iPad mini (A17 Pro)", "iPad mini (A17 Pro)"),
        "iPad16,3": ("11", "iPad Pro 11-inch (M4)", "iPad Pro 11-inch (M4)"),
        "iPad16,4": ("11", "iPad Pro 11-inch (M4)", "iPad Pro 11-inch (M4)"),
        "iPad16,5": ("13", "iPad Pro 13-inch (M4)", "iPad Pro 13-inch (M4)"),
        "iPad16,6": ("13", "iPad Pro 13-inch (M4)", "iPad Pro 13-inch (M4)"),
    ]

    private static let deviceMap: [String: (size: String, model: String, modelEn: String)] = iPhoneMap.merging(iPadMap) { current, _ in
        current
    }

    var sizeModel: (size: String, model: String, modelEn: String) {
        if UIDevice.current.isSimulator() {
            return ("Simulator", "Simulator", "Simulator")
        }

        if let model = Self.deviceMap[self.detailedModel] {
            return model
        }
        if self.detailedModel.hasPrefix("iPad") {
            return ("", "iPad", "iPad")
        }
        return ("", "", "")
    }
    /**
     是否越狱
     */
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
            "/Applications/SBSettings.app",
            "/Applications/blackra1n.app",
            "/Applications/IntelliScreen.app",
            "/Applications/Snoop-itConfig.app",
            "/bin/sh",
            "/usr/libexec/sftp-server",
            "/usr/libexec/ssh-keysign",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/bin/bash",
            "/usr/sbin/sshd",
            "/etc/apt",
            "/System/Library/LaunchDaemons/com.saurik.Cydia.Startup.plist",
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
