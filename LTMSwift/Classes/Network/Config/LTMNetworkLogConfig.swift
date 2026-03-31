//
//  LTMNetworkLogConfig.swift
//  LTMSwift
//

import Foundation

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
