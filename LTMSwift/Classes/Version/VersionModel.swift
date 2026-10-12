//
//  VersionModel.swift
//  LTMSwift
//
//  Created by coenen on 2026/10/12.
//

import Foundation

// App Store 版本信息，不包含界面行为。
public struct AppStoreInfoModel: Decodable {
    // 商店版本号。
    public let version: String
    // 商店详情链接。
    public let trackViewUrl: String
    // 可选更新说明。
    public let releaseNotes: String?

    /**
     创建商店版本信息。

     - parameters version 商店版本号
     - parameters trackViewUrl 商店详情链接
     - parameters releaseNotes 可选更新说明
     */
    public init(version: String, trackViewUrl: String, releaseNotes: String? = nil) {
        self.version = version
        self.trackViewUrl = trackViewUrl
        self.releaseNotes = releaseNotes
    }
}

// App Store 查询结果。
struct AppStoreLookupModel: Decodable {
    // 匹配的应用，空数组表示未找到。
    let results: [AppStoreInfoModel]
}

// 版本检查结果。
public struct VersionCheckModel {
    // 是否有更新。
    public let needsUpdate: Bool
    // 用于比较的本地版本。
    public let localVersion: String
    // 商店应用信息。
    public let storeInfo: AppStoreInfoModel

    /**
     创建版本检查结果。

     - parameters needsUpdate 是否有更新
     - parameters localVersion 用于比较的本地版本
     - parameters storeInfo 商店版本信息
     */
    public init(needsUpdate: Bool, localVersion: String, storeInfo: AppStoreInfoModel) {
        self.needsUpdate = needsUpdate
        self.localVersion = localVersion
        self.storeInfo = storeInfo
    }
}

public enum VersionError: Error {
    /** 版本号为空或不是点分隔的非负整数。 */
    case invalidVersion(String)
    /** 应用 ID 或地区参数无效。 */
    case invalidLookupParameters
    /** 网络返回了不符合预期的 HTTP 响应。 */
    case invalidResponse
    /** 指定地区未找到应用。 */
    case applicationNotFound
}
