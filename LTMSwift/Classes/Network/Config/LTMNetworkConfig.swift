//
//  LTMNetworkConfig.swift
//  LTMSwift
//

import Foundation

/// Global network behavior configuration.
public struct LTMNetworkConfig {
    /// Response parsing behavior.
    public var response: LTMNetworkResponseConfig

    /// Token refresh flow configuration.
    public var tokenRefresh: LTMNetworkTokenRefreshConfig

    /// Callback dispatch behavior.
    public var callback: LTMNetworkCallbackConfig

    /// Network observability behavior.
    public var observer: LTMNetworkObserverConfig

    /// Duplicate request guard configuration.
    public var duplicateRequest: LTMNetworkDuplicateRequestConfig

    /// Log output configuration.
    public var log: LTMNetworkLogConfig

    /// Creates a network config with sensible defaults.
    public init(
        response: LTMNetworkResponseConfig = .init(),
        tokenRefresh: LTMNetworkTokenRefreshConfig = .init(),
        callback: LTMNetworkCallbackConfig = .init(),
        observer: LTMNetworkObserverConfig = .init(),
        duplicateRequest: LTMNetworkDuplicateRequestConfig = .init(),
        log: LTMNetworkLogConfig = .init()
    ) {
        self.response = response
        self.tokenRefresh = tokenRefresh
        self.callback = callback
        self.observer = observer
        self.duplicateRequest = duplicateRequest
        self.log = log
    }
}
