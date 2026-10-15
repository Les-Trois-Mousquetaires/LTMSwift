//
//  LTMLogPlugin.swift
//  LTMSwift
//
//  Created by zsn on 2022/12/4.
//  请求Log输出

import Foundation
import Moya

open class LTMLogPlugin: PluginType {
    /// Unified log configuration. No legacy init path is kept.
    public var config: LTMNetworkLogConfig

    public init(config: LTMNetworkLogConfig = .init()) {
        self.config = config
    }

    open func willSend(_ request: RequestType, target: TargetType) {
        guard config.isEnabled else { return }
        guard let urlRequest = request.request else {
            log("[Network][Request] empty request")
            return
        }

        let method = urlRequest.httpMethod ?? "UNKNOWN"
        let url = urlRequest.url?.absoluteString ?? ""

        var lines = ["[Network][Request] \(method) \(url)"]
        if config.logHeaders {
            lines.append("[Network][Request Headers]\n\(formatJSON(redactedHeaders(urlRequest.allHTTPHeaderFields)) ?? "{}")")
        }
        if config.logBody {
            lines.append("[Network][Body]\n\(truncate(formatBody(urlRequest.httpBody)))")
        }
        log(lines.joined(separator: "\n"))
    }

    open func didReceive(_ result: Result<Response, MoyaError>, target: TargetType) {
        guard config.isEnabled else { return }

        switch result {
        case .success(let response):
            let url = response.request?.url?.absoluteString ?? ""
            let status = response.statusCode
            log("[Network][Response] status=\(status) url=\(url)")

            guard config.logBody else {
                log("[Network][Payload] <hidden>")
                return
            }

            if let json = try? response.mapJSON(), let pretty = formatJSON(json) {
                log("[Network][Payload] \(truncate(pretty))")
            } else if let text = String(data: response.data, encoding: .utf8), !text.isEmpty {
                log("[Network][Payload] \(truncate(text))")
            } else {
                log("[Network][Payload] <non-json data: \(response.data.count) bytes>")
            }

        case .failure(let error):
            let url = error.response?.request?.url?.absoluteString ?? ""
            log("[Network][Error] url=\(url) error=\(error.localizedDescription)")
        }
    }

    private func redactedHeaders(_ headers: [String: String]?) -> [String: String] {
        guard let headers else { return [:] }
        var result: [String: String] = [:]
        for (key, value) in headers {
            if config.redactedKeys.contains(key.lowercased()) {
                result[key] = "***"
            } else {
                result[key] = value
            }
        }
        return result
    }

    private func redactedJSON(_ object: Any) -> Any {
        if var dict = object as? [String: Any] {
            for key in dict.keys {
                if config.redactedKeys.contains(key.lowercased()) {
                    dict[key] = "***"
                } else if let nested = dict[key] {
                    dict[key] = redactedJSON(nested)
                }
            }
            return dict
        }

        if let list = object as? [Any] {
            return list.map { redactedJSON($0) }
        }

        return object
    }

    /**
     将脱敏后的内容格式化为 JSON，支持对象、数组和标量。

     - parameters object 待格式化的 JSON 内容
     */
    private func formatJSON(_ object: Any) -> String? {
        guard let data = try? JSONSerialization.data(
            withJSONObject: redactedJSON(object),
            options: [.prettyPrinted, .sortedKeys, .fragmentsAllowed, .withoutEscapingSlashes]
        ) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func formatBody(_ data: Data?) -> String {
        guard let data, !data.isEmpty else { return "<empty>" }

        if let json = try? JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed]),
           let pretty = formatJSON(json) {
            return pretty
        }

        if let text = String(data: data, encoding: .utf8), !text.isEmpty {
            return text
        }

        return "<binary: \(data.count) bytes>"
    }

    private func log(_ message: String) {
        if let logger = config.logger {
            logger(message)
        } else {
            print(message)
        }
    }

    private func truncate(_ text: String) -> String {
        guard config.maxBodyLogLength > 0, text.count > config.maxBodyLogLength else { return text }
        let head = text.prefix(config.maxBodyLogLength)
        return "\(head)... <truncated \(text.count - config.maxBodyLogLength) chars>"
    }
}
