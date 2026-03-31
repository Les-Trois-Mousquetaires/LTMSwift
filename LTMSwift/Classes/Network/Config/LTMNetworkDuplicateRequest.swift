//
//  LTMNetworkDuplicateRequest.swift
//  LTMSwift
//

import Foundation

/// Duplicate request guard configuration.
public struct LTMNetworkDuplicateRequestConfig {
    /// Enables duplicate request guard.
    public var isEnabled: Bool

    /// Minimum interval for same request fingerprint.
    public var minimumInterval: TimeInterval

    /// Custom duplicate request key provider.
    public var keyProvider: ((String, String, String) -> String)?

    /// Per-request minimum interval override provider.
    /// Return `nil` to fallback to `minimumInterval`.
    public var intervalProvider: ((String, String, String) -> TimeInterval?)?

    /// Custom duplicate request failure payload builder.
    public var failureBuilder: ((String, String) -> Any)?

    /// TTL for completed request records.
    public var recordTTL: TimeInterval

    /// Max count for completed request records.
    public var maxRecordCount: Int

    public init(
        isEnabled: Bool = false,
        minimumInterval: TimeInterval = 0.5,
        keyProvider: ((String, String, String) -> String)? = nil,
        intervalProvider: ((String, String, String) -> TimeInterval?)? = nil,
        failureBuilder: ((String, String) -> Any)? = nil,
        recordTTL: TimeInterval = 120,
        maxRecordCount: Int = 2000
    ) {
        self.isEnabled = isEnabled
        self.minimumInterval = minimumInterval
        self.keyProvider = keyProvider
        self.intervalProvider = intervalProvider
        self.failureBuilder = failureBuilder
        self.recordTTL = recordTTL
        self.maxRecordCount = maxRecordCount
    }
}
