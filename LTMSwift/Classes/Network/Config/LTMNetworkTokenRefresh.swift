//
//  LTMNetworkTokenRefresh.swift
//  LTMSwift
//

import Foundation

/// Token refresh flow configuration.
public struct LTMNetworkTokenRefreshConfig {
    /// Enables auto token refresh + retry flow.
    public var isEnabled: Bool

    /// Maximum retry count after refresh.
    public var maxRetryCount: Int

    /// Returns `true` when failure payload represents token expiration.
    public var expiredMatcher: ((Any?) -> Bool)?

    /// Performs refresh token request. Call `done(true/false)` when finished.
    public var refreshAction: (((@escaping (Bool) -> Void)) -> Void)?

    /// Timeout for token refresh action in seconds.
    public var timeout: TimeInterval

    /// Retry filter by request method/path. Return `true` to allow auto retry.
    public var pathFilter: ((String, String) -> Bool)?

    /// Called when token refresh fails.
    public var onRefreshFailed: ((Any?) -> Void)?

    public init(
        isEnabled: Bool = true,
        maxRetryCount: Int = 1,
        expiredMatcher: ((Any?) -> Bool)? = nil,
        refreshAction: (((@escaping (Bool) -> Void)) -> Void)? = nil,
        timeout: TimeInterval = 10,
        pathFilter: ((String, String) -> Bool)? = nil,
        onRefreshFailed: ((Any?) -> Void)? = nil
    ) {
        self.isEnabled = isEnabled
        self.maxRetryCount = maxRetryCount
        self.expiredMatcher = expiredMatcher
        self.refreshAction = refreshAction
        self.timeout = timeout
        self.pathFilter = pathFilter
        self.onRefreshFailed = onRefreshFailed
    }
}
