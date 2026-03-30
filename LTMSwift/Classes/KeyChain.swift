//
//  KeyChain.swift
//  Pods
//
//  Created by zsn on 2023/11/2.
//  钥匙串存储

import Foundation
import Security
import LocalAuthentication

public extension UIDevice {
    /// 获取设备唯一码
    ///
    func uniqueUUID(_ key: String) -> String {
        if let result = KeyChain.getData(key: key), !result.isEmpty {
            return result
        }

        let uuid = identifierForVendor?.uuidString ?? UUID().uuidString
        _ = KeyChain.save(key: key, data: uuid)
        return uuid
    }
}

public struct KeyChainQueryOptions {
    /// Keychain 分组（kSecAttrService）。
    /// 不传则默认使用 `key`，建议按业务模块分组（如 `com.company.auth`）。
    public var service: String?

    /// 账号标识（kSecAttrAccount）。
    /// 不传则默认使用 `key`，同 service 下可用 account 进一步区分条目。
    public var account: String?

    /// 是否启用 iCloud Keychain 同步（kSecAttrSynchronizable）。
    /// 默认 false。开启后在不支持同步环境可能返回 `errSecNotAvailable`。
    public var synchronizable: Bool

    /// 覆盖全局 `accessibleAttribute` 的单次可访问级别。
    /// 当 `accessControl` 不为空时，此字段会被忽略。
    public var accessible: CFString?

    /// 访问控制（生物识别/用户在场）。
    /// 设置后优先于 `accessible`，并写入 kSecAttrAccessControl。
    public var accessControl: SecAccessControl?

    /// 读取受保护条目时系统弹窗文案（kSecUseOperationPrompt）。
    public var authenticationPrompt: String?

    /// 读取受保护条目时自定义认证上下文（kSecUseAuthenticationContext）。
    public var authenticationContext: LAContext?

    public init(
        service: String? = nil,
        account: String? = nil,
        synchronizable: Bool = false,
        accessible: CFString? = nil,
        accessControl: SecAccessControl? = nil,
        authenticationPrompt: String? = nil,
        authenticationContext: LAContext? = nil
    ) {
        self.service = service
        self.account = account
        self.synchronizable = synchronizable
        self.accessible = accessible
        self.accessControl = accessControl
        self.authenticationPrompt = authenticationPrompt
        self.authenticationContext = authenticationContext
    }
}

open class KeyChain: NSObject {
    /// Keychain 可访问级别（kSecAttrAccessible），默认 `kSecAttrAccessibleAfterFirstUnlock`。
    ///
    /// 常用可选值：
    /// - `kSecAttrAccessibleWhenUnlocked`:
    ///   仅设备已解锁时可访问；安全性高，前台常用。
    /// - `kSecAttrAccessibleAfterFirstUnlock`:
    ///   设备重启后首次解锁后可访问；后台任务更友好（默认）。
    /// - `kSecAttrAccessibleAlways`:
    ///   始终可访问（已不推荐，尽量避免使用）。
    /// - `kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly`:
    ///   仅在设置了设备密码时可用，且不随备份迁移（高安全）。
    /// - `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`:
    ///   仅解锁时可用，且不随备份迁移。
    /// - `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`:
    ///   首次解锁后可用，且不随备份迁移。
    /// - `kSecAttrAccessibleAlwaysThisDeviceOnly`:
    ///   始终可访问且不迁移（已不推荐，尽量避免使用）。
    public static var accessibleAttribute: CFString = kSecAttrAccessibleAfterFirstUnlock

    /// 创建 AccessControl（用于生物识别/用户在场保护）
    /// - Parameters:
    ///   - accessible: 可访问级别，默认 `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`
    ///   - flags: 例如 `.biometryCurrentSet` / `.userPresence`
    public class func makeAccessControl(
        accessible: CFString = kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        flags: SecAccessControlCreateFlags = [.biometryCurrentSet]
    ) -> SecAccessControl? {
        var error: Unmanaged<CFError>?
        let control = SecAccessControlCreateWithFlags(nil, accessible, flags, &error)
        return control
    }

    /// 将 OSStatus 转换为可读文案，便于日志和业务提示。
    /// - Parameter status: Security 接口返回状态码。
    /// - Returns: 可读错误说明（优先系统文案，未命中时返回码值）。
    public class func statusMessage(_ status: OSStatus) -> String {
        switch status {
        case errSecSuccess: return "Success"
        case errSecItemNotFound: return "Item not found"
        case errSecDuplicateItem: return "Duplicate item"
        case errSecAuthFailed: return "Authentication failed"
        case errSecUserCanceled: return "User canceled"
        case errSecInteractionNotAllowed: return "Interaction not allowed"
        case errSecNotAvailable: return "Service not available"
        case errSecDecode: return "Decode failed"
        case errSecParam: return "Invalid parameter"
        default:
            if let msg = SecCopyErrorMessageString(status, nil) as String? {
                return msg
            }
            return "Security status: \(status)"
        }
    }

    // MARK: - 对外简化接口（Bool）
    /// 保存字符串。内部调用状态码接口，成功判定为 `errSecSuccess`。
    public class func save(key: String, data: String, options: KeyChainQueryOptions = KeyChainQueryOptions()) -> Bool {
        saveStatus(key: key, data: data, options: options) == errSecSuccess
    }

    public class func update(key: String, data: String, options: KeyChainQueryOptions = KeyChainQueryOptions()) -> Bool {
        updateStatus(key: key, data: data, options: options) == errSecSuccess
    }

    public class func getData(key: String, options: KeyChainQueryOptions = KeyChainQueryOptions()) -> String? {
        getDataStatus(key: key, options: options).value
    }

    public class func delete(key: String, options: KeyChainQueryOptions = KeyChainQueryOptions()) -> Bool {
        deleteStatus(key: key, options: options) == errSecSuccess
    }

    public class func saveObject<T: Codable>(
        key: String,
        object: T,
        options: KeyChainQueryOptions = KeyChainQueryOptions(),
        encoder: JSONEncoder = JSONEncoder()
    ) -> Bool {
        saveObjectStatus(key: key, object: object, options: options, encoder: encoder) == errSecSuccess
    }

    public class func getObject<T: Codable>(
        key: String,
        as type: T.Type,
        options: KeyChainQueryOptions = KeyChainQueryOptions(),
        decoder: JSONDecoder = JSONDecoder()
    ) -> T? {
        getObjectStatus(key: key, as: type, options: options, decoder: decoder).value
    }

    // MARK: - 对外状态码接口（OSStatus）
    /// 状态码接口用于排查失败原因（如参数错误、权限错误、同步不可用等）。
    @discardableResult
    public class func saveStatus(key: String, data: String, options: KeyChainQueryOptions = KeyChainQueryOptions()) -> OSStatus {
        guard let rawData = data.data(using: .utf8) else {
            return errSecParam
        }
        return saveRawDataStatus(key: key, data: rawData, options: options)
    }

    @discardableResult
    public class func updateStatus(key: String, data: String, options: KeyChainQueryOptions = KeyChainQueryOptions()) -> OSStatus {
        guard let rawData = data.data(using: .utf8) else {
            return errSecParam
        }
        return updateRawDataStatus(key: key, data: rawData, options: options)
    }

    public class func getDataStatus(key: String, options: KeyChainQueryOptions = KeyChainQueryOptions()) -> (status: OSStatus, value: String?) {
        let raw = getRawDataStatus(key: key, options: options)
        guard raw.status == errSecSuccess, let data = raw.data else {
            return (raw.status, nil)
        }

        // 优先读取新格式（UTF-8 原始字符串）
        if let result = String(data: data, encoding: .utf8) {
            return (errSecSuccess, result)
        }

        // 兼容老版本（NSKeyedArchiver/NSString）
        if let old = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSString.self, from: data) {
            let value = old as String
            // 迁移回写为新格式
            _ = saveStatus(key: key, data: value, options: options)
            return (errSecSuccess, value)
        }

        return (errSecDecode, nil)
    }

    @discardableResult
    public class func deleteStatus(key: String, options: KeyChainQueryOptions = KeyChainQueryOptions()) -> OSStatus {
        let query = getQuery(key: key, options: options)
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecItemNotFound ? errSecSuccess : status
    }

    @discardableResult
    public class func saveObjectStatus<T: Codable>(
        key: String,
        object: T,
        options: KeyChainQueryOptions = KeyChainQueryOptions(),
        encoder: JSONEncoder = JSONEncoder()
    ) -> OSStatus {
        guard let data = try? encoder.encode(object) else {
            return errSecParam
        }
        return saveRawDataStatus(key: key, data: data, options: options)
    }

    public class func getObjectStatus<T: Codable>(
        key: String,
        as type: T.Type,
        options: KeyChainQueryOptions = KeyChainQueryOptions(),
        decoder: JSONDecoder = JSONDecoder()
    ) -> (status: OSStatus, value: T?) {
        let raw = getRawDataStatus(key: key, options: options)
        guard raw.status == errSecSuccess, let data = raw.data else {
            return (raw.status, nil)
        }

        guard let value = try? decoder.decode(T.self, from: data) else {
            return (errSecDecode, nil)
        }
        return (errSecSuccess, value)
    }

    // MARK: - 内部原始数据接口
    private class func saveRawDataStatus(key: String, data: Data, options: KeyChainQueryOptions) -> OSStatus {
        var query = getQuery(key: key, options: options)
        _ = deleteStatus(key: key, options: options)
        query[kSecValueData] = data
        return SecItemAdd(query as CFDictionary, nil)
    }

    private class func updateRawDataStatus(key: String, data: Data, options: KeyChainQueryOptions) -> OSStatus {
        let query = getQuery(key: key, options: options)
        let updateParam: [CFString: Any] = [kSecValueData: data]
        let status = SecItemUpdate(query as CFDictionary, updateParam as CFDictionary)

        if status == errSecItemNotFound {
            return saveRawDataStatus(key: key, data: data, options: options)
        }
        return status
    }

    private class func getRawDataStatus(key: String, options: KeyChainQueryOptions) -> (status: OSStatus, data: Data?) {
        var query = getQuery(key: key, options: options)
        query[kSecReturnData] = kCFBooleanTrue
        query[kSecMatchLimit] = kSecMatchLimitOne

        if let prompt = options.authenticationPrompt, !prompt.isEmpty {
            query[kSecUseOperationPrompt] = prompt
        }

        if let context = options.authenticationContext {
            query[kSecUseAuthenticationContext] = context
        }

        var queryResult: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &queryResult)
        return (status, queryResult as? Data)
    }

    // MARK: - 查询参数
    private class func getQuery(key: String, options: KeyChainQueryOptions) -> [CFString: Any] {
        let service = options.service ?? key
        let account = options.account ?? key

        var query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ]

        if let accessControl = options.accessControl {
            query[kSecAttrAccessControl] = accessControl
        } else {
            query[kSecAttrAccessible] = options.accessible ?? accessibleAttribute
        }

        if options.synchronizable {
            query[kSecAttrSynchronizable] = kCFBooleanTrue
        }

        return query
    }
}
