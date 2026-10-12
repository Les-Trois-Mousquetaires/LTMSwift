//
//  NetworkParamPlugin.swift
//  LTMSwift
//
//  Created by coenen on 2026/10/12.
//

import Foundation
import Moya

// 同名公共参数与原请求参数的合并策略。
public enum NetworkParamMergePolicy {
    /** 保留原请求参数。 */
    case keepExisting
    /** 用公共参数覆盖原请求参数。 */
    case replaceExisting
}

// Body 参数注入格式，不推断 Multipart 或二进制内容。
public enum NetworkParamBodyEncoding {
    /** 根据 Content-Type 识别 JSON 或表单；无法识别时保持原样。 */
    case automatic
    /** 注入 JSON 对象；非对象 JSON 保持原样。 */
    case json
    /** 注入 application/x-www-form-urlencoded 表单。 */
    case form
}

public enum NetworkParamError: Error {
    /** 原请求体不是可合并的 JSON 对象。 */
    case invalidJSONObject
    /** 原表单无法按 UTF-8 读取。 */
    case invalidForm
    /** 公共表单参数包含不支持的类型。 */
    case unsupportedFormValue(String)
}

public final class NetworkParamPlugin: PluginType {
    private let queryProvider: ((TargetType) -> [String: String])?
    private let bodyProvider: ((TargetType) -> [String: Any])?
    private let mergePolicy: NetworkParamMergePolicy
    private let bodyEncoding: NetworkParamBodyEncoding
    private let errorHandler: ((Error, TargetType) -> Void)?

    /**
     创建公共参数插件；两个提供器均可省略，每次请求动态调用。

     - parameters queryProvider URL 参数提供器，调用方明确转换数字等值
     - parameters bodyProvider JSON 或表单参数提供器
     - parameters mergePolicy 同名参数策略，默认保留原请求
     - parameters bodyEncoding Body 格式，默认按 Content-Type 识别
     - parameters errorHandler Body 编码失败通知；失败时保留原 Body
     */
    public init(
        queryProvider: ((TargetType) -> [String: String])? = nil,
        bodyProvider: ((TargetType) -> [String: Any])? = nil,
        mergePolicy: NetworkParamMergePolicy = .keepExisting,
        bodyEncoding: NetworkParamBodyEncoding = .automatic,
        errorHandler: ((Error, TargetType) -> Void)? = nil
    ) {
        self.queryProvider = queryProvider
        self.bodyProvider = bodyProvider
        self.mergePolicy = mergePolicy
        self.bodyEncoding = bodyEncoding
        self.errorHandler = errorHandler
    }

    /**
     合并公共参数，保留请求方法、原请求头及不支持的请求体。

     - parameters request 已编码的请求
     - parameters target Moya 请求目标
     */
    public func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
        var result = request
        if let parameters = queryProvider?(target), !parameters.isEmpty,
           let url = result.url, var components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            let additions = parameters.keys.sorted().map { URLQueryItem(name: $0, value: parameters[$0]) }
            components.queryItems = mergeItems(components.queryItems ?? [], additions: additions)
            if let url = components.url { result.url = url }
        }
        let method = result.httpMethod?.uppercased() ?? "GET"
        guard method != "GET", method != "HEAD", result.httpBodyStream == nil,
              let parameters = bodyProvider?(target), !parameters.isEmpty else { return result }
        let contentType = (result.value(forHTTPHeaderField: "Content-Type") ?? "")
            .split(separator: ";").first.map(String.init)?.trimmingCharacters(in: .whitespaces).lowercased() ?? ""
        // 显式格式也不覆盖已经声明的上传或二进制格式。
        guard contentType.isEmpty || contentType == "application/json" || contentType.hasSuffix("+json")
                || contentType == "application/x-www-form-urlencoded" else { return result }
        let encoding: NetworkParamBodyEncoding
        switch bodyEncoding {
        case .automatic:
            if contentType == "application/json" || contentType.hasSuffix("+json") { encoding = .json }
            else if contentType == "application/x-www-form-urlencoded" { encoding = .form }
            else { return result }
        default:
            encoding = bodyEncoding
        }
        if encoding == .json, !contentType.isEmpty, contentType != "application/json", !contentType.hasSuffix("+json") { return result }
        if encoding == .form, !contentType.isEmpty, contentType != "application/x-www-form-urlencoded" { return result }
        do {
            switch encoding {
            case .json:
                var existing: [String: Any] = [:]
                if let data = result.httpBody, !data.isEmpty {
                    guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                        throw NetworkParamError.invalidJSONObject
                    }
                    existing = object
                }
                for (key, value) in parameters {
                    if existing[key] == nil || mergePolicy == .replaceExisting { existing[key] = value }
                }
                guard JSONSerialization.isValidJSONObject(existing) else { throw NetworkParamError.invalidJSONObject }
                result.httpBody = try JSONSerialization.data(withJSONObject: existing)
                if contentType.isEmpty { result.setValue("application/json", forHTTPHeaderField: "Content-Type") }
            case .form:
                let existingText: String
                if let data = result.httpBody {
                    guard let text = String(data: data, encoding: .utf8) else { throw NetworkParamError.invalidForm }
                    existingText = text
                } else { existingText = "" }
                let existing = try formItems(existingText)
                let additions = try parameters.keys.sorted().flatMap { key in
                    try formQueryItems(key: key, value: parameters[key]!)
                }
                var components = URLComponents()
                components.queryItems = mergeItems(existing, additions: additions)
                result.httpBody = Data((components.percentEncodedQuery ?? "").replacingOccurrences(of: "+", with: "%2B").utf8)
                result.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            case .automatic:
                break
            }
            result.setValue(nil, forHTTPHeaderField: "Content-Length")
        } catch {
            errorHandler?(error, target)
        }
        return result
    }

    /**
     按参数根键合并，保留数组重复项和未冲突的原参数。

     - parameters existing 原参数项
     - parameters additions 公共参数项
     */
    private func mergeItems(_ existing: [URLQueryItem], additions: [URLQueryItem]) -> [URLQueryItem] {
        let roots: (URLQueryItem) -> String = { $0.name.components(separatedBy: "[").first ?? $0.name }
        switch mergePolicy {
        case .keepExisting:
            let names = Set(existing.map(roots))
            return existing + additions.filter { !names.contains(roots($0)) }
        case .replaceExisting:
            let names = Set(additions.map(roots))
            return existing.filter { !names.contains(roots($0)) } + additions
        }
    }

    /**
     将表单值编码为键值对，数组和字典使用括号键。

     - parameters key 参数键
     - parameters value 参数值
     */
    private func formQueryItems(key: String, value: Any) throws -> [URLQueryItem] {
        if let dictionary = value as? [String: Any] {
            return try dictionary.keys.sorted().flatMap { child in
                try formQueryItems(key: "\(key)[\(child)]", value: dictionary[child]!)
            }
        }
        if let array = value as? [Any] {
            return try array.flatMap { try formQueryItems(key: "\(key)[]", value: $0) }
        }
        if value is NSNull { return [URLQueryItem(name: key, value: nil)] }
        if let text = value as? String { return [URLQueryItem(name: key, value: text)] }
        if let number = value as? NSNumber { return [URLQueryItem(name: key, value: number.stringValue)] }
        throw NetworkParamError.unsupportedFormValue(key)
    }

    /**
     解析表单键值，按表单规则将加号视为空格。

     - parameters text 表单文本
     */
    private func formItems(_ text: String) throws -> [URLQueryItem] {
        var components = URLComponents()
        let query = text.replacingOccurrences(of: "+", with: "%20")
        guard query.removingPercentEncoding != nil else { throw NetworkParamError.invalidForm }
        // 使用 URL 解析器避免对非法百分号序列设置属性时触发断言。
        guard let parsed = URLComponents(string: "https://localhost/?" + query) else { throw NetworkParamError.invalidForm }
        components.queryItems = parsed.queryItems
        return components.queryItems ?? []
    }
}
