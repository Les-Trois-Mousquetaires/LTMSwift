import XCTest
import Security
import LocalAuthentication
import LTMSwift

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
}
