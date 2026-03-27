import XCTest
import LTMSwift

final class Tests: XCTestCase {

    override func setUp() {
        super.setUp()
        LTMHUDManage.shared.ltm_dismissAll()
        LTMHUDManage.maxQueueCount = 20
        LTMHUDManage.deduplicateInterval = 0.8
        LTMHUDManage.overflowStrategy = .dropOldest
    }

    override func tearDown() {
        LTMHUDManage.shared.ltm_dismissAll()
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

        XCTAssertEqual(LTMHUDManage.shared.ltm_pendingCount, 2)
    }

    func testHUDDeduplicate() {
        LTMHUDManage.deduplicateInterval = 1.0

        LTMProgressHUD.show(.loading, "loading", 0)
        LTMProgressHUD.show(.none, "same", 1, priority: 0)
        LTMProgressHUD.show(.none, "same", 1, priority: 0)

        XCTAssertEqual(LTMHUDManage.shared.ltm_pendingCount, 1)
    }

    func testHUDLoadingSingleSlotReplace() {
        LTMProgressHUD.show(.none, "toast", 1, priority: 0)
        LTMProgressHUD.show(.loading, "loading-1", 1)
        LTMProgressHUD.show(.loading, "loading-2", 1)

        XCTAssertEqual(LTMHUDManage.shared.ltm_pendingCount, 1)
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
}
