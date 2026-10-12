//
//  VersionManager.swift
//  LTMSwift
//
//  Created by coenen on 2026/10/12.
//

import Foundation

public final class VersionManager {
    public static let shared = VersionManager()
    private let session: URLSession

    /**
     创建版本管理器，可注入 URLSession。

     - parameters session 网络会话
     */
    public init(session: URLSession = .shared) { self.session = session }

    /**
     获取指定 Bundle 的本地版本。

     - parameters bundle 应用或其他 Bundle
     */
    public func getLocalVersion(bundle: Bundle = .main) -> String { bundle.appVersion }

    /**
     按点分隔数字比较版本，缺失段视为 0，不接受预发布后缀。

     - parameters storeVer 商店版本
     - parameters localVer 本地版本
     */
    public func isNewVersion(storeVer: String, localVer: String) throws -> Bool {
        let store = try versionParts(storeVer)
        let local = try versionParts(localVer)
        for index in 0..<max(store.count, local.count) {
            let lhs = index < store.count ? store[index] : "0"
            let rhs = index < local.count ? local[index] : "0"
            if lhs.count != rhs.count { return lhs.count > rhs.count }
            if lhs != rhs { return lhs > rhs }
        }
        return false
    }

    /**
     查询 App Store 并返回版本结果，不展示弹窗、不打开商店。

     - parameters appId App Store 数字 ID
     - parameters country 两字母地区代码
     - parameters localVersion 可选本地版本，未指定时读取 bundle
     - parameters bundle 本地应用 Bundle
     */
    public func checkUpdate(
        appId: String,
        country: String = "us",
        localVersion: String? = nil,
        bundle: Bundle = .main
    ) async throws -> VersionCheckModel {
        let version = localVersion ?? getLocalVersion(bundle: bundle)
        _ = try versionParts(version)
        let region = country.lowercased()
        guard !appId.isEmpty, appId.utf8.allSatisfy({ (48...57).contains($0) }),
              region.utf8.count == 2, region.utf8.allSatisfy({ (97...122).contains($0) }) else {
            throw VersionError.invalidLookupParameters
        }
        var components = URLComponents()
        components.scheme = "https"
        components.host = "itunes.apple.com"
        components.path = "/lookup"
        components.queryItems = [URLQueryItem(name: "id", value: appId), URLQueryItem(name: "country", value: region)]
        guard let url = components.url else { throw VersionError.invalidLookupParameters }
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw VersionError.invalidResponse
        }
        let lookup = try JSONDecoder().decode(AppStoreLookupModel.self, from: data)
        guard let app = lookup.results.first else { throw VersionError.applicationNotFound }
        return VersionCheckModel(
            needsUpdate: try isNewVersion(storeVer: app.version, localVer: version),
            localVersion: version,
            storeInfo: app
        )
    }

    /**
     解析并移除版本段的前导零，避免整数转换溢出。

     - parameters value 点分隔数字版本
     */
    private func versionParts(_ value: String) throws -> [String] {
        let parts = value.split(separator: ".", omittingEmptySubsequences: false)
        guard !value.isEmpty, parts.allSatisfy({ !$0.isEmpty && $0.utf8.allSatisfy({ (48...57).contains($0) }) }) else {
            throw VersionError.invalidVersion(value)
        }
        return parts.map { part in
            let trimmed = part.drop(while: { $0 == "0" })
            return trimmed.isEmpty ? "0" : String(trimmed)
        }
    }
}
