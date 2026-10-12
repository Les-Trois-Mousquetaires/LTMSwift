//
//  Bundle+Extension.swift
//  LTMSwift
//
//  Created by coenen on 2026/10/12.
//

import Foundation

public extension Bundle {
    // 当前 Bundle 的版本号，缺失时返回空字符串。
    var appVersion: String { infoDictionary?["CFBundleShortVersionString"] as? String ?? "" }
    // 当前 Bundle 的构建号，缺失时返回空字符串。
    var appBuild: String { infoDictionary?["CFBundleVersion"] as? String ?? "" }
}
