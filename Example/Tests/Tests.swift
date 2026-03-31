import XCTest
import Security
import LocalAuthentication
import LTMSwift
import Moya

final class Tests: XCTestCase {

    override func setUp() {
        super.setUp()
        LTMHUDManage.shared.dismissAll()
        LTMHUDManage.maxQueueCount = 20
        LTMHUDManage.deduplicateInterval = 0.8
        LTMHUDManage.overflowStrategy = .dropOldest
    }

    override func tearDown() {
        LTMHUDManage.shared.dismissAll()
        super.tearDown()
    }

    func testHUDPriorityOrder() {
        let expectation = expectation(description: "priority order")
        var callbackOrder: [String] = []

        LTMProgressHUD.show(.loading, "loading", 0)
        LTMProgressHUD.show(.none, "low", 0.05, priority: 0) {
            callbackOrder.append("low")
        }
        LTMProgressHUD.show(.none, "high", 0.05, priority: 10) {
            callbackOrder.append("high")
            expectation.fulfill()
        }

        LTMProgressHUD.dismiss()

        wait(for: [expectation], timeout: 2.0)
        XCTAssertEqual(callbackOrder.first, "high")
    }

    func testHUDQueueMaxCount() {
        LTMHUDManage.maxQueueCount = 2
        LTMHUDManage.overflowStrategy = .dropOldest

        LTMProgressHUD.show(.loading, "loading", 0)
        LTMProgressHUD.show(.none, "A", 1, priority: 0)
        LTMProgressHUD.show(.none, "B", 1, priority: 0)
        LTMProgressHUD.show(.none, "C", 1, priority: 0)

        XCTAssertEqual(LTMHUDManage.shared.pendingCount, 2)
    }

    func testHUDDeduplicate() {
        LTMHUDManage.deduplicateInterval = 1.0

        LTMProgressHUD.show(.loading, "loading", 0)
        LTMProgressHUD.show(.none, "same", 1, priority: 0)
        LTMProgressHUD.show(.none, "same", 1, priority: 0)

        XCTAssertEqual(LTMHUDManage.shared.pendingCount, 1)
    }

    func testHUDLoadingSingleSlotReplace() {
        LTMProgressHUD.show(.none, "toast", 1, priority: 0)
        LTMProgressHUD.show(.loading, "loading-1", 1)
        LTMProgressHUD.show(.loading, "loading-2", 1)

        XCTAssertEqual(LTMHUDManage.shared.pendingCount, 1)
    }

    func testHUDInterruptCurrentViaParameter() {
        let expectation = expectation(description: "interrupt current")
        var callbackOrder: [String] = []

        LTMProgressHUD.show(.none, "first", 0.2, priority: 0) {
            callbackOrder.append("first")
        }
        LTMProgressHUD.show(.none, "second", 0.05, priority: 0, interruptCurrent: true) {
            callbackOrder.append("second")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2.0)
        XCTAssertEqual(callbackOrder.first, "second")
        XCTAssertFalse(callbackOrder.contains("first"))
    }

    func testKeyChainSaveUpdateGetDelete() {
        let key = "test.keychain.save.update.\(UUID().uuidString)"

        XCTAssertTrue(KeyChain.save(key: key, data: "A"))
        XCTAssertEqual(KeyChain.getData(key: key), "A")

        XCTAssertTrue(KeyChain.update(key: key, data: "B"))
        XCTAssertEqual(KeyChain.getData(key: key), "B")

        XCTAssertTrue(KeyChain.delete(key: key))
        XCTAssertNil(KeyChain.getData(key: key))
    }

    func testKeyChainDeleteNotFoundReturnsTrue() {
        let key = "test.keychain.notfound.\(UUID().uuidString)"
        XCTAssertTrue(KeyChain.delete(key: key))
    }

    func testKeyChainLegacyArchivedStringMigrationRead() {
        let key = "test.keychain.legacy.\(UUID().uuidString)"
        defer { _ = KeyChain.delete(key: key) }

        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: key,
            kSecAttrAccount: key,
            kSecAttrAccessible: KeyChain.accessibleAttribute
        ]

        _ = SecItemDelete(query as CFDictionary)

        let archived = try? NSKeyedArchiver.archivedData(withRootObject: NSString(string: "legacy-value"), requiringSecureCoding: true)
        XCTAssertNotNil(archived)

        var addQuery = query
        addQuery[kSecValueData] = archived
        let status = SecItemAdd(addQuery as CFDictionary, nil)
        XCTAssertEqual(status, errSecSuccess)

        XCTAssertEqual(KeyChain.getData(key: key), "legacy-value")
    }

    func testUniqueUUIDFallbackAndConsistency() {
        let key = "test.keychain.uuid.\(UUID().uuidString)"
        defer { _ = KeyChain.delete(key: key) }

        let uuid1 = UIDevice.current.uniqueUUID(key)
        let uuid2 = UIDevice.current.uniqueUUID(key)

        XCTAssertFalse(uuid1.isEmpty)
        XCTAssertEqual(uuid1, uuid2)
    }

    func testKeyChainStatusAndServiceAccountOptions() {
        let key = "test.keychain.status.\(UUID().uuidString)"
        let options = KeyChainQueryOptions(service: "svc.demo", account: "acc.demo")
        defer { _ = KeyChain.delete(key: key, options: options) }

        let saveStatus = KeyChain.saveStatus(key: key, data: "status-value", options: options)
        XCTAssertEqual(saveStatus, errSecSuccess)

        let fetched = KeyChain.getDataStatus(key: key, options: options)
        XCTAssertEqual(fetched.status, errSecSuccess)
        XCTAssertEqual(fetched.value, "status-value")

        // 默认 service/account 与自定义隔离
        XCTAssertNil(KeyChain.getData(key: key))
    }

    func testKeyChainLegacyMigrationWillRewriteAsUtf8() {
        let key = "test.keychain.migrate.rewrite.\(UUID().uuidString)"
        let options = KeyChainQueryOptions()
        defer { _ = KeyChain.delete(key: key, options: options) }

        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: key,
            kSecAttrAccount: key,
            kSecAttrAccessible: KeyChain.accessibleAttribute,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]

        _ = SecItemDelete(query as CFDictionary)

        let archived = try? NSKeyedArchiver.archivedData(withRootObject: NSString(string: "legacy-rewrite"), requiringSecureCoding: true)
        XCTAssertNotNil(archived)

        var addQuery = query
        addQuery.removeValue(forKey: kSecReturnData)
        addQuery.removeValue(forKey: kSecMatchLimit)
        addQuery[kSecValueData] = archived
        XCTAssertEqual(SecItemAdd(addQuery as CFDictionary, nil), errSecSuccess)

        // 读取会触发迁移回写
        XCTAssertEqual(KeyChain.getData(key: key, options: options), "legacy-rewrite")

        var raw: AnyObject?
        XCTAssertEqual(SecItemCopyMatching(query as CFDictionary, &raw), errSecSuccess)
        let rawData = raw as? Data
        XCTAssertNotNil(rawData)
        XCTAssertEqual(String(data: rawData ?? Data(), encoding: .utf8), "legacy-rewrite")
    }

    func testKeyChainCodableRoundTrip() {
        struct Profile: Codable, Equatable {
            let id: Int
            let name: String
        }

        let key = "test.keychain.codable.\(UUID().uuidString)"
        defer { _ = KeyChain.delete(key: key) }

        let profile = Profile(id: 1, name: "LTM")
        XCTAssertTrue(KeyChain.saveObject(key: key, object: profile))

        let loaded = KeyChain.getObject(key: key, as: Profile.self)
        XCTAssertEqual(loaded, profile)
    }

    func testKeyChainSynchronizableOption() {
        let key = "test.keychain.sync.\(UUID().uuidString)"
        let options = KeyChainQueryOptions(synchronizable: true)
        defer { _ = KeyChain.delete(key: key, options: options) }

        // 在不支持同步的环境也应返回有效状态码（非崩溃）
        let status = KeyChain.saveStatus(key: key, data: "sync-value", options: options)
        XCTAssertTrue(status == errSecSuccess || status == errSecNotAvailable)
    }

    func testKeyChainMakeAccessControl() {
        let access = KeyChain.makeAccessControl(flags: [.userPresence])
        XCTAssertNotNil(access)
    }

    func testNetworkAutoRefreshRetrySuccess() {
        let deal = LTMNetworkDeal()
        var refreshCount = 0
        deal.applyConfig { config in
            config.callback.onMainThread = false
            config.tokenRefresh.isEnabled = true
            config.tokenRefresh.maxRetryCount = 1
            config.tokenRefresh.expiredMatcher = { raw in
                guard let dict = raw as? [String: Any], let code = dict["code"] as? String else { return false }
                return code == "403"
            }
            config.tokenRefresh.refreshAction = { done in
                refreshCount += 1
                done(true)
            }
        }

        let provider = MoyaProvider<NetworkStubTarget>(stubClosure: MoyaProvider.immediatelyStub)
        NetworkStubQueue.shared.set([
            jsonData(["code": "403", "message": "expired"]),
            jsonData(["code": "200", "data": ["id": 1, "name": "ok"]])
        ])

        let successExp = expectation(description: "auto retry success")
        deal.request(
            provider: provider,
            target: .protectedData,
            model: NetworkTestModel(),
            successBlock: { result in
                XCTAssertEqual(result?.id, 1)
                XCTAssertEqual(result?.name, "ok")
                successExp.fulfill()
            },
            failureBlock: { _ in
                XCTFail("Should retry and succeed")
            }
        )

        wait(for: [successExp], timeout: 2.0)
        XCTAssertEqual(refreshCount, 1)
    }

    func testNetworkRefreshFailureCallbackAndFailureOutput() {
        let deal = LTMNetworkDeal()
        let refreshFailExp = expectation(description: "refresh failed callback")

        deal.applyConfig { config in
            config.callback.onMainThread = false
            config.tokenRefresh.isEnabled = true
            config.tokenRefresh.maxRetryCount = 1
            config.tokenRefresh.expiredMatcher = { raw in
                guard let dict = raw as? [String: Any], let code = dict["code"] as? String else { return false }
                return code == "403"
            }
            config.tokenRefresh.refreshAction = { done in done(false) }
            config.tokenRefresh.onRefreshFailed = { _ in
                refreshFailExp.fulfill()
            }
        }

        let failureExp = expectation(description: "final failure callback")
        let provider = MoyaProvider<NetworkStubTarget>(stubClosure: MoyaProvider.immediatelyStub)
        NetworkStubQueue.shared.set([
            jsonData(["code": "403", "message": "expired"])
        ])

        deal.request(
            provider: provider,
            target: .protectedData,
            model: NetworkTestModel(),
            successBlock: { _ in
                XCTFail("Refresh failed, should not succeed")
            },
            failureBlock: { _ in
                failureExp.fulfill()
            }
        )

        wait(for: [refreshFailExp, failureExp], timeout: 2.0)
    }

    func testNetworkSingleFlightRefreshForConcurrentRequests() {
        let deal = LTMNetworkDeal()
        var refreshCount = 0

        deal.applyConfig { config in
            config.callback.onMainThread = false
            config.tokenRefresh.isEnabled = true
            config.tokenRefresh.maxRetryCount = 1
            config.tokenRefresh.expiredMatcher = { raw in
                guard let dict = raw as? [String: Any], let code = dict["code"] as? String else { return false }
                return code == "403"
            }
            config.tokenRefresh.refreshAction = { done in
                refreshCount += 1
                DispatchQueue.global().asyncAfter(deadline: .now() + 0.05) {
                    done(true)
                }
            }
        }

        let provider = MoyaProvider<NetworkStubTarget>(stubClosure: MoyaProvider.immediatelyStub)
        NetworkStubQueue.shared.set([
            jsonData(["code": "403", "message": "expired-1"]),
            jsonData(["code": "403", "message": "expired-2"]),
            jsonData(["code": "200", "data": ["id": 11, "name": "A"]]),
            jsonData(["code": "200", "data": ["id": 22, "name": "B"]])
        ])

        let successExp = expectation(description: "two requests success")
        successExp.expectedFulfillmentCount = 2

        for _ in 0..<2 {
            deal.request(
                provider: provider,
                target: .protectedData,
                model: NetworkTestModel(),
                successBlock: { _ in
                    successExp.fulfill()
                },
                failureBlock: { _ in
                    XCTFail("Both requests should succeed after single refresh")
                }
            )
        }

        wait(for: [successExp], timeout: 3.0)
        XCTAssertEqual(refreshCount, 1)
    }

    func testNetworkDuplicateRequestGuardBlocksSameRequest() {
        let deal = LTMNetworkDeal()
        deal.applyConfig { config in
            config.callback.onMainThread = false
            config.duplicateRequest.isEnabled = true
            config.duplicateRequest.minimumInterval = 2
        }

        let provider = MoyaProvider<NetworkStubTarget>(stubClosure: MoyaProvider.immediatelyStub)
        NetworkStubQueue.shared.set([
            jsonData(["code": "200", "data": ["id": 1, "name": "ok"]])
        ])

        let successExp = expectation(description: "first request success")
        let duplicateExp = expectation(description: "duplicate blocked")

        deal.request(
            provider: provider,
            target: .protectedData,
            model: NetworkTestModel(),
            successBlock: { _ in
                successExp.fulfill()
            },
            failureBlock: { _ in
                XCTFail("First request should succeed")
            }
        )

        deal.request(
            provider: provider,
            target: .protectedData,
            model: NetworkTestModel(),
            successBlock: { _ in
                XCTFail("Duplicate request should be blocked")
            },
            failureBlock: { failure in
                guard let dict = failure as? [String: Any], let error = dict["error"] as? String else {
                    XCTFail("Expected duplicate error payload")
                    return
                }
                XCTAssertEqual(error, "duplicate-request")
                duplicateExp.fulfill()
            }
        )

        wait(for: [successExp, duplicateExp], timeout: 2.0)
    }

    func testNetworkRefreshTimeoutFallsBackToFailure() {
        let deal = LTMNetworkDeal()
        let refreshFailExp = expectation(description: "refresh timeout callback")
        let failureExp = expectation(description: "final failure callback")

        deal.applyConfig { config in
            config.callback.onMainThread = false
            config.tokenRefresh.isEnabled = true
            config.tokenRefresh.maxRetryCount = 1
            config.tokenRefresh.timeout = 0.05
            config.tokenRefresh.expiredMatcher = { raw in
                guard let dict = raw as? [String: Any], let code = dict["code"] as? String else { return false }
                return code == "403"
            }
            config.tokenRefresh.refreshAction = { _ in
                // Intentionally do not callback to trigger timeout.
            }
            config.tokenRefresh.onRefreshFailed = { _ in
                refreshFailExp.fulfill()
            }
        }

        let provider = MoyaProvider<NetworkStubTarget>(stubClosure: MoyaProvider.immediatelyStub)
        NetworkStubQueue.shared.set([
            jsonData(["code": "403", "message": "expired"])
        ])

        deal.request(
            provider: provider,
            target: .protectedData,
            model: NetworkTestModel(),
            successBlock: { _ in
                XCTFail("Timeout should not succeed")
            },
            failureBlock: { _ in
                failureExp.fulfill()
            }
        )

        wait(for: [refreshFailExp, failureExp], timeout: 2.0)
    }
}

private struct NetworkTestModel: LTMModel {
    var id: Int?
    var name: String?
}

private enum NetworkStubTarget: TargetType {
    case protectedData

    var baseURL: URL { URL(string: "https://example.com")! }
    var path: String { "/protected" }
    var method: Moya.Method { .get }
    var sampleData: Data { NetworkStubQueue.shared.next() }
    var task: Task { .requestPlain }
    var headers: [String: String]? { nil }
}

private final class NetworkStubQueue {
    static let shared = NetworkStubQueue()

    private let lock = NSLock()
    private var queue: [Data] = []

    func set(_ data: [Data]) {
        lock.lock()
        queue = data
        lock.unlock()
    }

    func next() -> Data {
        lock.lock()
        defer { lock.unlock() }
        guard !queue.isEmpty else {
            return jsonData(["code": "200", "data": [:]])
        }
        return queue.removeFirst()
    }
}

private func jsonData(_ object: [String: Any]) -> Data {
    (try? JSONSerialization.data(withJSONObject: object, options: [])) ?? Data("{}".utf8)
}
