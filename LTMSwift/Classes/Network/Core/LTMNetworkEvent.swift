//
//  LTMNetworkEvent.swift
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
