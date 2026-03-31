//
//  LTMNetworkCallbackConfig.swift
//  LTMSwift
//

import Foundation

/// Callback dispatch behavior configuration.
public struct LTMNetworkCallbackConfig {
    /// Whether callbacks are dispatched on main thread.
    public var onMainThread: Bool

    public init(onMainThread: Bool = true) {
        self.onMainThread = onMainThread
    }
}
