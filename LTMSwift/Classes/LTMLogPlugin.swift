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

        log("[Network][Request] \(method) \(url)")
        if config.logHeaders {
            log("[Network][Headers] \(redactedHeaders(urlRequest.allHTTPHeaderFields))")
        }

        guard config.logBody else { return }
        log("[Network][Body] \(truncate(formatBody(urlRequest.httpBody)))")
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

            if let json = try? response.mapJSON() {
                log("[Network][Payload] \(truncate("\(redactedJSON(json))"))")
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

    private func formatBody(_ data: Data?) -> String {
        guard let data, !data.isEmpty else { return "<empty>" }

        if let json = try? JSONSerialization.jsonObject(with: data, options: []),
           let prettyData = try? JSONSerialization.data(withJSONObject: redactedJSON(json), options: [.prettyPrinted]),
           let pretty = String(data: prettyData, encoding: .utf8) {
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
