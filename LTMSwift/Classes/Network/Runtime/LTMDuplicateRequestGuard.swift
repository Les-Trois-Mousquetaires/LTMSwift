//
//  LTMDuplicateRequestGuard.swift
//  LTMSwift
//

import Foundation

enum LTMDuplicateRequestRegisterResult {
    case allowed
    case rejected(reason: String)
}

final class LTMDuplicateRequestGuard {
    private let queue = DispatchQueue(label: "com.ltmswift.network.duplicate.guard")
    private let queueKey = DispatchSpecificKey<Void>()
    private var inFlight: Set<String> = []
    private var lastCompletedAt: [String: TimeInterval] = [:]

    init() {
        queue.setSpecific(key: queueKey, value: ())
    }

    func register(
        key: String,
        minimumInterval: TimeInterval,
        recordTTL: TimeInterval,
        maxRecordCount: Int
    ) -> LTMDuplicateRequestRegisterResult {
        performSync {
            let now = Date().timeIntervalSince1970
            compact(now: now, recordTTL: recordTTL, maxRecordCount: maxRecordCount)

            if inFlight.contains(key) {
                return .rejected(reason: "in-flight")
            }

            if let last = lastCompletedAt[key], now - last < minimumInterval {
                return .rejected(reason: "too-frequent")
            }

            inFlight.insert(key)
            return .allowed
        }
    }

    func complete(key: String) {
        performSync {
            self.inFlight.remove(key)
            self.lastCompletedAt[key] = Date().timeIntervalSince1970
        }
    }

    private func performSync<T>(_ work: () -> T) -> T {
        if DispatchQueue.getSpecific(key: queueKey) != nil {
            return work()
        }
        return queue.sync(execute: work)
    }

    private func compact(now: TimeInterval, recordTTL: TimeInterval, maxRecordCount: Int) {
        if recordTTL > 0 {
            lastCompletedAt = lastCompletedAt.filter { now - $0.value <= recordTTL }
        }

        if maxRecordCount > 0, lastCompletedAt.count > maxRecordCount {
            let sorted = lastCompletedAt.sorted { $0.value < $1.value }
            let overflow = lastCompletedAt.count - maxRecordCount
            for index in 0..<overflow {
                lastCompletedAt.removeValue(forKey: sorted[index].key)
            }
        }
    }
}
