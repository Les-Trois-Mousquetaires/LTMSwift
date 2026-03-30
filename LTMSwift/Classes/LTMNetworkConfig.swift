//
//  LTMNetworkConfig.swift
//  LTMSwift
//

import Foundation

/// Network lifecycle events for observability.
public enum LTMNetworkEvent {
    /// Auto retry was skipped with a reason.
    case autoRetrySkipped(reason: String, method: String, path: String, retryCount: Int)

    /// Token refresh started for a failed request.
    case tokenRefreshStarted(method: String, path: String, retryCount: Int)

    /// Token refresh finished.
    case tokenRefreshFinished(success: Bool, method: String, path: String)

    /// Original request is retried after refresh.
    case requestRetried(method: String, path: String, retryCount: Int)

    /// Duplicate request was blocked by guard.
    case duplicateRequestBlocked(reason: String, method: String, path: String)
}

/// Log plugin configuration.
public struct LTMNetworkLogConfig {
    /// Enables network logging output.
    public var isEnabled: Bool

    /// Whether request headers should be printed.
    public var logHeaders: Bool

    /// Whether request body should be printed.
    public var logBody: Bool

    /// Max body log length. Longer payload will be truncated.
    public var maxBodyLogLength: Int

    /// Optional custom logger. Defaults to `print` when nil.
    public var logger: ((String) -> Void)?

    /// Sensitive keys to redact in headers and JSON payloads.
    public var redactedKeys: Set<String>

    public init(
        isEnabled: Bool = true,
        logHeaders: Bool = true,
        logBody: Bool = true,
        maxBodyLogLength: Int = 8000,
        logger: ((String) -> Void)? = nil,
        redactedKeys: Set<String> = ["authorization", "token", "password", "pwd", "secret", "cookie"]
    ) {
        self.isEnabled = isEnabled
        self.logHeaders = logHeaders
        self.logBody = logBody
        self.maxBodyLogLength = maxBodyLogLength
        self.logger = logger
        self.redactedKeys = redactedKeys
    }
}

/// Global network behavior configuration.
public struct LTMNetworkConfig {
    /// Response key for business status code. Example: `code`.
    public var codeKey: String

    /// Expected success code value. Example: `200`.
    public var codeSuccess: String

    /// Accepted HTTP status codes.
    public var successStatusCodes: Set<Int>

    /// Response key that contains business payload. Example: `data`.
    public var dataKey: String

    /// Whether callbacks are dispatched on main thread.
    public var callbackOnMainThread: Bool

    /// Enables auto token refresh + retry flow.
    public var enableAutoTokenRefresh: Bool

    /// Maximum retry count after refresh.
    public var maxAutoRetryCount: Int

    /// Returns `true` when failure payload represents token expiration.
    public var tokenExpiredMatcher: ((Any?) -> Bool)?

    /// Performs refresh token request. Call `done(true/false)` when finished.
    public var tokenRefreshAction: (((@escaping (Bool) -> Void)) -> Void)?

    /// Timeout for token refresh action in seconds.
    public var tokenRefreshTimeout: TimeInterval

    /// Retry filter by request method/path. Return `true` to allow auto retry.
    public var autoRetryPathFilter: ((String, String) -> Bool)?

    /// Called when token refresh fails.
    public var onTokenRefreshFailed: ((Any?) -> Void)?

    /// Optional observability callback.
    public var networkEventHandler: ((LTMNetworkEvent) -> Void)?

    /// Enables duplicate request guard.
    public var enableDuplicateRequestGuard: Bool

    /// Minimum interval for same request fingerprint.
    public var duplicateRequestInterval: TimeInterval

    /// Custom duplicate request key provider.
    public var duplicateRequestKeyProvider: ((String, String, String) -> String)?

    /// Custom duplicate request failure payload builder.
    public var duplicateRequestFailureBuilder: ((String, String) -> Any)?

    /// Log output configuration.
    public var log: LTMNetworkLogConfig

    /// Creates a network config with sensible defaults.
    public init(
        codeKey: String = "code",
        codeSuccess: String = "200",
        successStatusCodes: Set<Int> = Set(200...299),
        dataKey: String = "data",
        callbackOnMainThread: Bool = true,
        enableAutoTokenRefresh: Bool = true,
        maxAutoRetryCount: Int = 1,
        tokenExpiredMatcher: ((Any?) -> Bool)? = nil,
        tokenRefreshAction: (((@escaping (Bool) -> Void)) -> Void)? = nil,
        tokenRefreshTimeout: TimeInterval = 10,
        autoRetryPathFilter: ((String, String) -> Bool)? = nil,
        onTokenRefreshFailed: ((Any?) -> Void)? = nil,
        networkEventHandler: ((LTMNetworkEvent) -> Void)? = nil,
        enableDuplicateRequestGuard: Bool = false,
        duplicateRequestInterval: TimeInterval = 0.5,
        duplicateRequestKeyProvider: ((String, String, String) -> String)? = nil,
        duplicateRequestFailureBuilder: ((String, String) -> Any)? = nil,
        log: LTMNetworkLogConfig = .init()
    ) {
        self.codeKey = codeKey
        self.codeSuccess = codeSuccess
        self.successStatusCodes = successStatusCodes
        self.dataKey = dataKey
        self.callbackOnMainThread = callbackOnMainThread
        self.enableAutoTokenRefresh = enableAutoTokenRefresh
        self.maxAutoRetryCount = maxAutoRetryCount
        self.tokenExpiredMatcher = tokenExpiredMatcher
        self.tokenRefreshAction = tokenRefreshAction
        self.tokenRefreshTimeout = tokenRefreshTimeout
        self.autoRetryPathFilter = autoRetryPathFilter
        self.onTokenRefreshFailed = onTokenRefreshFailed
        self.networkEventHandler = networkEventHandler
        self.enableDuplicateRequestGuard = enableDuplicateRequestGuard
        self.duplicateRequestInterval = duplicateRequestInterval
        self.duplicateRequestKeyProvider = duplicateRequestKeyProvider
        self.duplicateRequestFailureBuilder = duplicateRequestFailureBuilder
        self.log = log
    }
}
