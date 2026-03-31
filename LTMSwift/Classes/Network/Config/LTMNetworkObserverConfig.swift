//
//  LTMNetworkObserverConfig.swift
//  LTMSwift
//

import Foundation

/// Network observability configuration.
public struct LTMNetworkObserverConfig {
    /// Optional observability callback.
    public var eventHandler: ((LTMNetworkEvent) -> Void)?

    public init(eventHandler: ((LTMNetworkEvent) -> Void)? = nil) {
        self.eventHandler = eventHandler
    }
}
