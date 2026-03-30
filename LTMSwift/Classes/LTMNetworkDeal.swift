//
//  LTMNetworkDeal.swift
//  LTMSwift
//
//  Created by zsn on 2022/12/4.
//

import Foundation
import Moya
import SmartCodable

/// Base network deal class.
///
/// - Parses response using `codeKey` / `codeSuccess` / `dataKey`.
/// - Provides unified `request(...)` entry.
/// - Supports optional auto token refresh + auto retry.
open class LTMNetworkDeal: NSObject {

    /// Global network behavior configuration.
    public var config: LTMNetworkConfig

    public override init() {
        self.config = LTMNetworkConfig()
        super.init()
    }

    public init(config: LTMNetworkConfig) {
        self.config = config
        super.init()
    }

    /// One-time configuration entry.
    ///
    /// Recommended usage: call in your `NetworkManager` initializer.
    public func applyConfig(_ configure: (inout LTMNetworkConfig) -> Void) {
        configure(&config)
    }

    /// Creates a log plugin from current config.
    public func makeLogPlugin() -> LTMLogPlugin {
        LTMLogPlugin(config: config.log)
    }

    /// Guarantees single-flight token refresh when multiple requests fail concurrently.
    private let tokenRefreshCoordinator = LTMTokenRefreshCoordinator()

    /// Prevents duplicated same-fingerprint requests in a short time window.
    private let duplicateRequestGuard = LTMDuplicateRequestGuard()

    /// Parses `Moya` response and dispatches success/failure callbacks.
    ///
    /// You can still override `failureHandle(data:)` for unified business error mapping.
    public func handleData<T: LTMModel>(model: T, response: Result<Response, MoyaError>, successBlock: ((_ result: T?) -> Void)?, failureBlock: ((_ result: Any?) -> Void)?) {
        switch response {
        case .success(let success):
            guard let data = (try? success.mapJSON()) as? [String: Any] else {
                invokeFailure(failureBlock, result: [
                    "statusCode": success.statusCode,
                    "error": "Invalid response JSON. Expected [String: Any]."
                ])
                return
            }

            if self.config.successStatusCodes.contains(success.statusCode) {
                let code = "\(data[self.config.codeKey] ?? "")"
                switch code {
                case self.config.codeSuccess:
                    let targetData = data[self.config.dataKey] ?? data
                    invokeSuccess(successBlock, result: successHandle(data: targetData, model: model))
                default:
                    invokeFailure(failureBlock, result: failureHandle(data: data))
                }
            } else {
                invokeFailure(failureBlock, result: failureHandle(data: data))
            }

        case .failure(let failure):
            invokeFailure(failureBlock, result: failureHandle(data: failure))
        }
    }

    /// Unified request entry.
    ///
    /// Internal flow: request -> handleData -> (if needed) refresh token -> auto retry.
    open func request<Target: TargetType, Model: LTMModel>(
        provider: MoyaProvider<Target>,
        target: Target,
        model: Model,
        successBlock: ((_ result: Model?) -> Void)?,
        failureBlock: ((_ result: Any?) -> Void)?
    ) {
        request(
            provider: provider,
            target: target,
            model: model,
            retryCount: 0,
            successBlock: successBlock,
            failureBlock: failureBlock
        )
    }

    private func request<Target: TargetType, Model: LTMModel>(
        provider: MoyaProvider<Target>,
        target: Target,
        model: Model,
        retryCount: Int,
        successBlock: ((_ result: Model?) -> Void)?,
        failureBlock: ((_ result: Any?) -> Void)?,
        bypassDuplicateGuard: Bool = false
    ) {
        let method = target.method.rawValue
        let path = target.path
        let requestKey = makeRequestKey(target)
        let effectiveKey = config.duplicateRequestKeyProvider?(method, path, requestKey) ?? requestKey

        var didRegisterDuplicateGuard = false
        if !bypassDuplicateGuard && config.enableDuplicateRequestGuard {
            let result = duplicateRequestGuard.register(key: effectiveKey, minimumInterval: config.duplicateRequestInterval)
            if case let .rejected(reason) = result {
                emit(.duplicateRequestBlocked(reason: reason, method: method, path: path))
                let failurePayload = config.duplicateRequestFailureBuilder?(method, path) ?? [
                    "error": "duplicate-request",
                    "reason": reason,
                    "method": method,
                    "path": path
                ]
                invokeFailure(failureBlock, result: failureHandle(data: failurePayload))
                return
            }
            didRegisterDuplicateGuard = true
        }

        provider.request(target) { [weak self] result in
            guard let self else { return }

            defer {
                if didRegisterDuplicateGuard {
                    self.duplicateRequestGuard.complete(key: effectiveKey)
                }
            }

            self.handleData(model: model, response: result, successBlock: successBlock, failureBlock: { [weak self] failure in
                guard let self else { return }

                guard self.config.enableAutoTokenRefresh else {
                    self.emit(.autoRetrySkipped(reason: "disabled", method: method, path: path, retryCount: retryCount))
                    self.invokeFailure(failureBlock, result: failure)
                    return
                }

                guard retryCount < self.config.maxAutoRetryCount else {
                    self.emit(.autoRetrySkipped(reason: "max-retry-reached", method: method, path: path, retryCount: retryCount))
                    self.invokeFailure(failureBlock, result: failure)
                    return
                }

                if let filter = self.config.autoRetryPathFilter, !filter(method, path) {
                    self.emit(.autoRetrySkipped(reason: "path-filtered", method: method, path: path, retryCount: retryCount))
                    self.invokeFailure(failureBlock, result: failure)
                    return
                }

                guard
                    let matcher = self.config.tokenExpiredMatcher,
                    let refreshAction = self.config.tokenRefreshAction,
                    matcher(failure)
                else {
                    self.emit(.autoRetrySkipped(reason: "not-token-expired", method: method, path: path, retryCount: retryCount))
                    self.invokeFailure(failureBlock, result: failure)
                    return
                }

                self.emit(.tokenRefreshStarted(method: method, path: path, retryCount: retryCount))

                // Single-flight refresh: only one refresh request runs at a time.
                self.tokenRefreshCoordinator.refreshIfNeeded(refreshAction, timeout: self.config.tokenRefreshTimeout) { [weak self] refreshed in
                    guard let self else { return }
                    self.emit(.tokenRefreshFinished(success: refreshed, method: method, path: path))

                    if refreshed {
                        // Refresh succeeded -> automatically replay original request.
                        self.emit(.requestRetried(method: method, path: path, retryCount: retryCount + 1))
                        self.request(
                            provider: provider,
                            target: target,
                            model: model,
                            retryCount: retryCount + 1,
                            successBlock: successBlock,
                            failureBlock: failureBlock,
                            bypassDuplicateGuard: true
                        )
                    } else {
                        self.config.onTokenRefreshFailed?(failure)
                        self.invokeFailure(failureBlock, result: failure)
                    }
                }
            })
        }
    }
    
    private func successHandle<T: LTMModel>(data: Any, model: T) -> T? {
        if let dict = data as? [String: Any] {
            return T.deserialize(from: dict)
        }

        return nil
    }
    
    /// Business-side unified error mapping hook.
    ///
    /// Override this in your subclass to map raw server error payload into your own error model.
    open func failureHandle(data: Any) -> Any? {
        return data
    }

    private func invokeSuccess<T>(_ callback: ((_ result: T?) -> Void)?, result: T?) {
        guard let callback else { return }
        if config.callbackOnMainThread {
            DispatchQueue.main.async {
                callback(result)
            }
        } else {
            callback(result)
        }
    }

    private func invokeFailure(_ callback: ((_ result: Any?) -> Void)?, result: Any?) {
        guard let callback else { return }
        if config.callbackOnMainThread {
            DispatchQueue.main.async {
                callback(result)
            }
        } else {
            callback(result)
        }
    }

    private func emit(_ event: LTMNetworkEvent) {
        config.networkEventHandler?(event)
    }

    private func makeRequestKey<Target: TargetType>(_ target: Target) -> String {
        let method = target.method.rawValue
        let url = target.baseURL.appendingPathComponent(target.path).absoluteString
        let headers = (target.headers ?? [:])
            .sorted { $0.key < $1.key }
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
        let task = normalizedTaskDescription(target.task)
        return "\(method)|\(url)|\(headers)|\(task)"
    }

    private func normalizedTaskDescription(_ task: Task) -> String {
        switch task {
        case .requestPlain:
            return "plain"
        case let .requestData(data):
            return "data:\(data.base64EncodedString())"
        case let .requestJSONEncodable(encodable):
            return "jsonEncodable:\(String(describing: encodable))"
        case let .requestCustomJSONEncodable(encodable, _):
            return "customJsonEncodable:\(String(describing: encodable))"
        case let .requestParameters(parameters, _):
            return "parameters:\(canonicalDictionaryString(parameters))"
        case let .requestCompositeData(bodyData: bodyData, urlParameters: urlParameters):
            return "compositeData:body=\(bodyData.base64EncodedString())&url=\(canonicalDictionaryString(urlParameters))"
        case let .requestCompositeParameters(bodyParameters: bodyParameters, bodyEncoding: _, urlParameters: urlParameters):
            return "compositeParams:body=\(canonicalDictionaryString(bodyParameters))&url=\(canonicalDictionaryString(urlParameters))"
        case let .uploadFile(url):
            return "uploadFile:\(url.absoluteString)"
        case let .uploadMultipart(formData):
            let parts = formData.map(multipartPartDescription).joined(separator: "||")
            return "uploadMultipart:\(parts)"
        case let .uploadCompositeMultipart(formData, urlParameters):
            let parts = formData.map(multipartPartDescription).joined(separator: "||")
            return "uploadCompositeMultipart:parts=\(parts)&url=\(canonicalDictionaryString(urlParameters))"
        case .downloadDestination:
            return "downloadDestination"
        case let .downloadParameters(parameters, _, _):
            return "downloadParameters:\(canonicalDictionaryString(parameters))"
        @unknown default:
            return "unknown:\(String(describing: task))"
        }
    }

    private func canonicalDictionaryString(_ dictionary: [String: Any]) -> String {
        guard JSONSerialization.isValidJSONObject(dictionary),
              let data = try? JSONSerialization.data(withJSONObject: dictionary, options: [.sortedKeys]),
              let json = String(data: data, encoding: .utf8) else {
            return dictionary
                .map { "\($0.key)=\(String(describing: $0.value))" }
                .sorted()
                .joined(separator: "&")
        }
        return json
    }

    private func multipartPartDescription(_ part: MultipartFormData) -> String {
        let payload: String
        switch part.provider {
        case let .data(data):
            payload = "data:\(data.base64EncodedString())"
        case let .file(url):
            payload = "file:\(url.absoluteString)"
        case let .stream(_, length):
            payload = "stream:\(length)"
        }

        return [
            part.name,
            part.fileName ?? "",
            part.mimeType ?? "",
            payload
        ].joined(separator: "|")
    }
}

private final class LTMDuplicateRequestGuard {
    enum RegisterResult {
        case allowed
        case rejected(reason: String)
    }

    private let queue = DispatchQueue(label: "com.ltmswift.network.duplicate.guard")
    private var inFlight: Set<String> = []
    private var lastCompletedAt: [String: TimeInterval] = [:]

    func register(key: String, minimumInterval: TimeInterval) -> RegisterResult {
        queue.sync {
            if inFlight.contains(key) {
                return .rejected(reason: "in-flight")
            }

            let now = Date().timeIntervalSince1970
            if let last = lastCompletedAt[key], now - last < minimumInterval {
                return .rejected(reason: "too-frequent")
            }

            inFlight.insert(key)
            return .allowed
        }
    }

    func complete(key: String) {
        queue.async {
            self.inFlight.remove(key)
            self.lastCompletedAt[key] = Date().timeIntervalSince1970
        }
    }
}

/// Coordinates refresh requests and fan-outs result to all waiting requests.
private final class LTMTokenRefreshCoordinator {
    private let queue = DispatchQueue(label: "com.ltmswift.network.token.refresh")
    private var isRefreshing = false
    private var waiters: [(Bool) -> Void] = []

    func refreshIfNeeded(_ action: @escaping (@escaping (Bool) -> Void) -> Void, timeout: TimeInterval, completion: @escaping (Bool) -> Void) {
        queue.async {
            self.waiters.append(completion)
            guard !self.isRefreshing else { return }

            self.isRefreshing = true
            var didFinish = false

            let finish: (Bool) -> Void = { success in
                self.queue.async {
                    guard !didFinish else { return }
                    didFinish = true
                    self.isRefreshing = false
                    let callbacks = self.waiters
                    self.waiters.removeAll()
                    callbacks.forEach { $0(success) }
                }
            }

            if timeout > 0 {
                self.queue.asyncAfter(deadline: .now() + timeout) {
                    guard !didFinish else { return }
                    didFinish = true
                    self.isRefreshing = false
                    let callbacks = self.waiters
                    self.waiters.removeAll()
                    callbacks.forEach { $0(false) }
                }
            }

            action { success in
                finish(success)
            }
        }
    }
}
