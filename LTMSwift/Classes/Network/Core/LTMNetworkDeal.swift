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
/// - Parses response using `response.codeKey` / `response.successCodes` / `response.dataKey`.
/// - Provides unified `request(...)` entry.
/// - Supports optional auto token refresh + auto retry.
open class LTMNetworkDeal: NSObject {

    /// Backing storage for global network behavior configuration.
    private var _config: LTMNetworkConfig
    private let configQueue = DispatchQueue(label: "com.ltmswift.network.config", attributes: .concurrent)

    /// Thread-safe network behavior configuration.
    public var config: LTMNetworkConfig {
        get { configQueue.sync { _config } }
        set { configQueue.sync(flags: .barrier) { _config = newValue } }
    }

    public override init() {
        self._config = LTMNetworkConfig()
        super.init()
    }

    public init(config: LTMNetworkConfig) {
        self._config = config
        super.init()
    }

    /// One-time configuration entry.
    ///
    /// Recommended usage: call in your `NetworkManager` initializer.
    public func applyConfig(_ configure: (inout LTMNetworkConfig) -> Void) {
        configQueue.sync(flags: .barrier) {
            configure(&_config)
        }
    }

    /// Creates a log plugin from current config.
    public func makeLogPlugin() -> LTMLogPlugin {
        LTMLogPlugin(config: currentConfig().log)
    }

    private func currentConfig() -> LTMNetworkConfig {
        configQueue.sync { _config }
    }

    /// Guarantees single-flight token refresh when multiple requests fail concurrently.
    private let tokenRefreshCoordinator = LTMTokenRefreshCoordinator()

    /// Prevents duplicated same-fingerprint requests in a short time window.
    private let duplicateRequestGuard = LTMDuplicateRequestGuard()

    /// Parses `Moya` response and dispatches success/failure callbacks.
    ///
    /// You can still override `failureHandle(data:)` for unified business error mapping.
    public func handleData<T: LTMModel>(model: T, response: Result<Response, MoyaError>, successBlock: ((_ result: T?) -> Void)?, failureBlock: ((_ result: Any?) -> Void)?) {
        let cfg = currentConfig()

        switch response {
        case .success(let success):
            guard let data = (try? success.mapJSON()) as? [String: Any] else {
                let invalidPayload: [String: Any] = [
                    "statusCode": success.statusCode,
                    "error": "Invalid response JSON. Expected [String: Any]."
                ]
                invokeFailure(failureBlock, result: failureHandle(data: invalidPayload))
                return
            }

            if cfg.response.successStatusCodes.contains(success.statusCode) {
                let responseCode = normalizedResponseCode(from: data[cfg.response.codeKey])

                var expectedCodes = Set(cfg.response.successCodes.map { normalizedResponseCode(from: $0) })
                expectedCodes.remove("")

                if expectedCodes.contains(responseCode) {
                    let targetData = data[cfg.response.dataKey] ?? data
                    invokeSuccess(successBlock, result: successHandle(data: targetData))
                } else {
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
        let cfg = currentConfig()
        let method = target.method.rawValue
        let path = target.path
        let requestKey = makeRequestKey(target)
        let duplicateCfg = cfg.duplicateRequest
        let effectiveKey = duplicateCfg.keyProvider?(method, path, requestKey) ?? requestKey

        var didRegisterDuplicateGuard = false
        if !bypassDuplicateGuard && duplicateCfg.isEnabled {
            let effectiveMinimumInterval = duplicateCfg.intervalProvider?(method, path, effectiveKey) ?? duplicateCfg.minimumInterval
            let result = duplicateRequestGuard.register(
                key: effectiveKey,
                minimumInterval: effectiveMinimumInterval,
                recordTTL: duplicateCfg.recordTTL,
                maxRecordCount: duplicateCfg.maxRecordCount
            )
            if case let .rejected(reason) = result {
                emit(.duplicateRequestBlocked(reason: reason, method: method, path: path))
                let failurePayload = duplicateCfg.failureBuilder?(method, path) ?? [
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

                let cfg = self.currentConfig()

                let tokenCfg = cfg.tokenRefresh

                guard tokenCfg.isEnabled else {
                    self.emit(.autoRetrySkipped(reason: "disabled", method: method, path: path, retryCount: retryCount))
                    self.invokeFailure(failureBlock, result: failure)
                    return
                }

                guard retryCount < tokenCfg.maxRetryCount else {
                    self.emit(.autoRetrySkipped(reason: "max-retry-reached", method: method, path: path, retryCount: retryCount))
                    self.invokeFailure(failureBlock, result: failure)
                    return
                }

                if let filter = tokenCfg.pathFilter, !filter(method, path) {
                    self.emit(.autoRetrySkipped(reason: "path-filtered", method: method, path: path, retryCount: retryCount))
                    self.invokeFailure(failureBlock, result: failure)
                    return
                }

                guard
                    let matcher = tokenCfg.expiredMatcher,
                    let refreshAction = tokenCfg.refreshAction,
                    matcher(failure)
                else {
                    self.emit(.autoRetrySkipped(reason: "not-token-expired", method: method, path: path, retryCount: retryCount))
                    self.invokeFailure(failureBlock, result: failure)
                    return
                }

                self.emit(.tokenRefreshStarted(method: method, path: path, retryCount: retryCount))

                // Single-flight refresh: only one refresh request runs at a time.
                self.tokenRefreshCoordinator.refreshIfNeeded(refreshAction, timeout: tokenCfg.timeout) { [weak self] refreshed in
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
                        tokenCfg.onRefreshFailed?(failure)
                        self.invokeFailure(failureBlock, result: failure)
                    }
                }
            })
        }
    }
    
    private func successHandle<T: LTMModel>(data: Any) -> T? {
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
        if currentConfig().callback.onMainThread {
            DispatchQueue.main.async {
                callback(result)
            }
        } else {
            callback(result)
        }
    }

    private func invokeFailure(_ callback: ((_ result: Any?) -> Void)?, result: Any?) {
        guard let callback else { return }
        if currentConfig().callback.onMainThread {
            DispatchQueue.main.async {
                callback(result)
            }
        } else {
            callback(result)
        }
    }

    private func emit(_ event: LTMNetworkEvent) {
        currentConfig().observer.eventHandler?(event)
    }

    private func normalizedResponseCode(from raw: Any?) -> String {
        guard let raw else { return "" }

        if let value = raw as? String {
            return value.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if let value = raw as? NSNumber {
            if CFGetTypeID(value) == CFBooleanGetTypeID() {
                return value.boolValue ? "true" : "false"
            }

            let doubleValue = value.doubleValue
            if doubleValue.rounded() == doubleValue {
                return String(Int64(doubleValue))
            }
            return String(doubleValue)
        }

        return String(describing: raw).trimmingCharacters(in: .whitespacesAndNewlines)
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
            return "data:\(dataHashToken(data))"
        case let .requestJSONEncodable(encodable):
            return "jsonEncodable:\(String(describing: encodable))"
        case let .requestCustomJSONEncodable(encodable, _):
            return "customJsonEncodable:\(String(describing: encodable))"
        case let .requestParameters(parameters, _):
            return "parameters:\(canonicalDictionaryString(parameters))"
        case let .requestCompositeData(bodyData: bodyData, urlParameters: urlParameters):
            return "compositeData:body=\(dataHashToken(bodyData))&url=\(canonicalDictionaryString(urlParameters))"
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

    private func dataHashToken(_ data: Data) -> String {
        "len=\(data.count),sha256=\(String.sha256(data: data))"
    }

    private func multipartPartDescription(_ part: MultipartFormData) -> String {
        let payload: String
        switch part.provider {
        case let .data(data):
            payload = "data:\(dataHashToken(data))"
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
