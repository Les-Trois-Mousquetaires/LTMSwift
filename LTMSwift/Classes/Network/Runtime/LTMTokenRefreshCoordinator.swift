//
//  LTMTokenRefreshCoordinator.swift
//  LTMSwift
//

import Foundation

/// Coordinates refresh requests and fan-outs result to all waiting requests.
final class LTMTokenRefreshCoordinator {
    private let queue = DispatchQueue(label: "com.ltmswift.network.token.refresh")
    private var isRefreshing = false
    private var waiters: [(Bool) -> Void] = []

    func refreshIfNeeded(
        _ action: @escaping (@escaping (Bool) -> Void) -> Void,
        timeout: TimeInterval,
        completion: @escaping (Bool) -> Void
    ) {
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
