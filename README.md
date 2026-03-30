# LTMSwift

[中文文档](README.zh-CN.md)

[![CI Status](https://img.shields.io/travis/kenan0620/LTMSwift.svg?style=flat)](https://travis-ci.org/kenan0620/LTMSwift)
[![Version](https://img.shields.io/cocoapods/v/LTMSwift.svg?style=flat)](https://cocoapods.org/pods/LTMSwift)
[![License](https://img.shields.io/cocoapods/l/LTMSwift.svg?style=flat)](https://cocoapods.org/pods/LTMSwift)
[![Platform](https://img.shields.io/cocoapods/p/LTMSwift.svg?style=flat)](https://cocoapods.org/pods/LTMSwift)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

LTMSwift is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'LTMSwift'
```

If you only need specific modules:

```ruby
pod 'LTMSwift/Extension'
pod 'LTMSwift/Extension/UIExtension'
pod 'LTMSwift/Extension/BaseExtension'
```

## CoreDataManager Quick Start

```swift
import LTMSwift

let manager = CoreDataManager.shared

// 1) Set your .xcdatamodeld name (without extension)
manager.coreDataName = "AppModel"

// 2) Use main/background context
let viewContext = manager.managerContext
let bgContext = manager.backgroundContext

// 3) Save changes safely
manager.saveContent(viewContext)
manager.saveContent(bgContext)

// 4) Clear one entity
manager.clearStorage(entityName: "UserEntity")
```

Tip: `coreDataName` must match your app's `.xcdatamodeld` name exactly.

## KeyChain Quick Start

```swift
import LocalAuthentication
import LTMSwift

let key = "secure.token"

// 1) Basic save/get
let ok = KeyChain.save(key: key, data: "token_value")
let value = KeyChain.getData(key: key)

// 2) Biometry-protected item
let access = KeyChain.makeAccessControl(flags: [.biometryCurrentSet])
let options = KeyChainQueryOptions(
    service: "com.demo.auth",
    account: "token",
    accessControl: access,
    authenticationPrompt: "Authenticate to read secure token"
)

let saveStatus = KeyChain.saveStatus(key: key, data: "secure_token", options: options)
let read = KeyChain.getDataStatus(key: key, options: options)

if read.status == errSecSuccess {
    print("token:", read.value ?? "")
} else {
    print(KeyChain.statusMessage(read.status))
}

// 3) Codable object
struct Profile: Codable { let id: Int; let name: String }
_ = KeyChain.saveObject(key: "profile", object: Profile(id: 1, name: "LTM"))
let profile = KeyChain.getObject(key: "profile", as: Profile.self)
```

Common statuses:
- `errSecSuccess`: success
- `errSecUserCanceled`: user canceled biometric prompt
- `errSecAuthFailed`: biometric failed
- `errSecInteractionNotAllowed`: current context does not allow interaction
- `errSecItemNotFound`: item does not exist
- `errSecNotAvailable`: service/biometry unavailable

Tip: For troubleshooting, prefer `saveStatus/getDataStatus/deleteStatus` + `KeyChain.statusMessage(_:)`.

### KeyChain Migration Notes

- Legacy `NSString` archived data is auto-migrated on first successful read.
- Recommended migration flow: keep key names unchanged, read once with new API, then persist with `saveStatus`.
- If historical data may be mixed, prioritize `getDataStatus` so you can log exact status and decide retry/fallback.

### Accessibility Selection Guide

| Scenario | Suggested `accessible` | Notes |
| --- | --- | --- |
| General token/session | `kSecAttrAccessibleAfterFirstUnlock` | Available after first unlock, works in background use cases |
| High-security secrets | `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` | Only when device unlocked, not migrated to another device |
| Needs device migration | `kSecAttrAccessibleWhenUnlocked` | Can migrate via backup/restore |
| Long background availability + this device only | `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` | Background-friendly and non-migrating |

### Biometry Full Flow (Save + Read + Result Handling)

```swift
import LocalAuthentication
import LTMSwift

let key = "bio.token"

// 1) Build access control
let access = KeyChain.makeAccessControl(flags: [.biometryCurrentSet, .userPresence])

// 2) Query options for this secure item
let context = LAContext()
context.localizedCancelTitle = "Use Password"

let options = KeyChainQueryOptions(
    service: "com.demo.secure",
    account: "login_token",
    accessControl: access,
    authenticationPrompt: "Authenticate to access secure token",
    authenticationContext: context
)

// 3) Save and check whether persistence succeeded
let saveStatus = KeyChain.saveStatus(key: key, data: "token_123", options: options)
guard saveStatus == errSecSuccess else {
    print("save failed:", KeyChain.statusMessage(saveStatus))
    // e.g. errSecAuthFailed / errSecInteractionNotAllowed / errSecParam
    return
}

// 4) Read and determine biometric result from status
let readResult = KeyChain.getDataStatus(key: key, options: options)
switch readResult.status {
case errSecSuccess:
    print("read success:", readResult.value ?? "")
case errSecUserCanceled:
    print("user canceled biometric dialog")
case errSecAuthFailed:
    print("biometric verification failed")
case errSecInteractionNotAllowed:
    print("interaction not allowed in current app state")
default:
    print("read failed:", KeyChain.statusMessage(readResult.status))
}
```

### Biometry Behavior Notes

- Biometric success/failure is reflected by read/update status (`errSecSuccess` / `errSecAuthFailed` / `errSecUserCanceled`), not by `makeAccessControl`.
- `makeAccessControl(...)` only creates a `SecAccessControl?` policy object; `nil` means policy creation failed.
- `saveStatus == errSecSuccess` means data was actually written.
- If app is backgrounded or UI interaction is blocked, you may get `errSecInteractionNotAllowed`.

### App-side Unified Error Handling Template

```swift
import Security
import LTMSwift

enum SecureReadResult {
    case success(String)
    case userCanceled
    case retryable(String)
    case fallbackToPassword(String)
    case fatal(String)
}

func handleKeychainStatus(_ status: OSStatus, value: String?) -> SecureReadResult {
    switch status {
    case errSecSuccess:
        return .success(value ?? "")

    case errSecUserCanceled:
        return .userCanceled

    case errSecInteractionNotAllowed:
        return .retryable("Interaction is not allowed now. Retry shortly.")

    case errSecAuthFailed:
        return .fallbackToPassword("Biometric verification failed. Use password.")

    case errSecItemNotFound:
        return .fallbackToPassword("Secure data not found. Please sign in again.")

    default:
        return .fatal(KeyChain.statusMessage(status))
    }
}

func readSecureToken() {
    let key = "bio.token"
    let access = KeyChain.makeAccessControl(flags: [.biometryCurrentSet])
    let options = KeyChainQueryOptions(
        service: "com.demo.secure",
        account: "login_token",
        accessControl: access,
        authenticationPrompt: "Authenticate to continue"
    )

    let result = KeyChain.getDataStatus(key: key, options: options)
    switch handleKeychainStatus(result.status, value: result.value) {
    case .success(let token):
        print("read success:", token)
    case .userCanceled:
        print("user canceled; keep flow calm")
    case .retryable(let tip):
        print("retryable:", tip)
    case .fallbackToPassword(let tip):
        print("fallback:", tip)
    case .fatal(let msg):
        print("fatal:", msg)
    }
}
```

Recommendations:
- Treat `errSecUserCanceled` as expected behavior (no global error toast).
- For `errSecInteractionNotAllowed`, delayed retry is usually better than immediate failure.
- For `errSecAuthFailed`, cap retries and move to password fallback.

## Network Quick Start (Auto Refresh + Retry)

```swift
import LTMSwift
import Moya

final class NetworkManager: LTMNetworkDeal {
    static let shared = NetworkManager()

    private lazy var logPlugin = makeLogPlugin()
    private lazy var loginProvider = MoyaProvider<LoginApi>(plugins: [logPlugin])
    private lazy var meProvider = MoyaProvider<MeApi>(plugins: [logPlugin])

    private override init() {
        super.init()

        applyConfig { config in
            config.enableAutoTokenRefresh = true
            config.maxAutoRetryCount = 1
            config.tokenRefreshTimeout = 8
            config.successStatusCodes = Set(200...299)

            config.enableDuplicateRequestGuard = true
            config.duplicateRequestInterval = 0.5

            config.log.isEnabled = true
            config.log.logHeaders = true
            config.log.logBody = false
            config.log.maxBodyLogLength = 4000
            config.log.redactedKeys.insert("set-cookie")
            config.log.logger = { message in
                print(message)
            }

            config.autoRetryPathFilter = { method, path in
                // e.g. do not retry payment/order submit APIs
                return !(method == "POST" && path.contains("/order/submit"))
            }

            config.tokenExpiredMatcher = { raw in
                guard let dict = raw as? [String: Any] else { return false }
                return (dict["code"] as? String) == "403"
            }

            config.tokenRefreshAction = { done in
                // do refresh token request here
                // done(true): refresh success, auto retry original request
                // done(false): refresh failed, call failure block
                done(true)
            }

            config.onTokenRefreshFailed = { raw in
                // unified failure handling (logout / toast / route to login)
                print("refresh failed:", raw ?? "nil")
            }

            config.networkEventHandler = { event in
                // optional metrics/observability hook
                print("network event:", event)
            }
        }
    }

    func loginRequest(model: UserInfoModel, success: resultBlcok?, failure: resultBlcok?) {
        request(
            provider: loginProvider,
            target: .login,
            model: model,
            successBlock: success,
            failureBlock: failure
        )
    }

    func meRequest(model: MeModel, success: resultBlcok?, failure: resultBlcok?) {
        request(
            provider: meProvider,
            target: .me,
            model: model,
            successBlock: success,
            failureBlock: failure
        )
    }
}
```

Business-side usage:

```swift
NetworkManager.shared.meRequest(model: MeModel()) { result in
    guard let me = result as? MeModel else { return }
    print("me success:", me)
} failure: { error in
    print("me failed:", error ?? "nil")
}
```

Notes:
- Response key mapping is configured once in `applyConfig` (`codeKey` / `codeSuccess` / `dataKey`) and reused by all APIs.
- `successStatusCodes` allows 2xx success strategy (default `200...299`).
- `tokenRefreshTimeout` prevents refresh flow from hanging forever if callback is missing.
- `enableDuplicateRequestGuard` blocks identical requests in-flight or in a short interval.
- Log config is centralized in `applyConfig`; use `log.logger` to route logs and `log.maxBodyLogLength` to cap payload output.
- `request(...)` internally uses Moya `provider.request(...)` and adds optional auto refresh + retry.
- Use `handleData(...)` / `failureHandle(data:)` as unified business parsing and error mapping hooks.
- Set `tokenExpiredMatcher` + `tokenRefreshAction` to enable refresh+retry; otherwise request failures return directly.

Token refresh failure template:

```swift
config.onTokenRefreshFailed = { raw in
    // 1) clear local auth state
    // 2) route to login page
    // 3) report event with raw payload
}
```

## Extension Quick Start (By File)

### BaseExtension

#### `Dictionary+Extension.swift`

```swift
let raw: [String: Any] = ["name": "LTM", "ext": NSNull()]
let cleaned = raw.removingNullValues()
let json = cleaned.jsonString
```

Tip: `jsonString` is optional, check for `nil` before upload/store.

#### `Array+Extension.swift`

```swift
let array = [1, 2, 3]
let json = array.jsonString
```

Tip: `toJSONString(prettyPrinted: true)` is useful for logs.

#### `String+Extension.swift`

```swift
let json = "{\"name\":\"LTM\"}"
let obj = json.jsonDictionary
```

Tip: invalid JSON returns `nil`.

#### `String+Encryption.swift`

```swift
let encoded = "LTMSwift".base64Encoded
let decoded = encoded?.base64Decoded
```

#### `String+Extension.swift` (Random)

```swift
let token = String.random(length: 16, includeNumbers: true)
```

### UIExtension

#### `UIControl+Extension.swift`

```swift
import LTMSwift

// Enable once (e.g. in AppDelegate)
UIControl.enableGlobalDebounce()

// Per-control interval
button.ltmDebounceInterval = 1.0
switchControl.ltmDebounceInterval = 0.5

// Disable debounce on one control
button.ltmDebounceInterval = 0
```

Tip: default debounce is `1.0s` for `UIButton`, `0` for other `UIControl`.

#### `UIGestureRecognizer+Debounce.swift`

```swift
imageView.addDebouncedTapGesture(interval: 1.0, target: self, action: #selector(onTapImage))
label.addDebouncedTapGesture(interval: 0.8, target: self, action: #selector(onTapLabel))

@objc private func onTapImage() {}
@objc private func onTapLabel() {}
```

Tip: debounce only applies to this added gesture; other gestures are unaffected.

#### `UIApplication+Extension.swift`

```swift
let window = UIApplication.shared.curWindow
let topVC = UIApplication.shared.curTopVC
```

#### `UIColor+Extension.swift`

```swift
let c1 = UIColor(hexString: "#FF6A00")
let c2 = UIColor(hexString: "0x00C2FF", alpha: 0.6)
let c3 = UIColor(hexString: "333")
```

#### `UIView+Extension.swift`

```swift
view.setGradient(
    startPoint: CGPoint(x: 0, y: 0),
    endPoint: CGPoint(x: 1, y: 0),
    colors: [UIColor.red.cgColor, UIColor.orange.cgColor]
)

view.drawDashLine(lineColor: .lightGray, isHorizonal: true)

let img1 = view.viewImage
let img2 = view.layerImage
```

#### `UITextField+Extension.swift`

```swift
textField.maxLength = 20
textField.digits = 2
textField.maxNumber = 9999
textField.limitBlock = { reason in
    print("limit reason:", reason)
}
```

Tip: `maxLength` / `digits` / `maxNumber` can be used together.

#### `UITextView+Extension.swift`

```swift
textView.placeholder = "请输入内容"
textView.placeholderColor = .lightGray
textView.maxLength = 200
```

#### `UIDevice+Extension.swift`

```swift
let isBang = UIDevice.current.isBangScreen
let top = UIDevice.current.topHeight
let model = UIDevice.current.sizeModel.model
let modelEn = UIDevice.current.sizeModel.modelEn
```

Tip: if model is unknown, you can fallback to `UIDevice.current.detailedModel`.

#### `LTMHUDManage.swift`

```swift
// Access
// UIViewController / UIView both support: HUDManage.xxx(...)

// 1) Global config (set once, e.g. in AppDelegate)
LTMHUDManage.isReceiveEvent = false // false: block touch, true: allow touch through
LTMHUDManage.maxQueueCount = 20
LTMHUDManage.deduplicateInterval = 0.8
LTMHUDManage.overflowStrategy = .dropOldest // or .dropNewest

// Style
LTMHUDManage.maxTextWidth = UIScreen.main.bounds.width - 100
LTMHUDManage.labelFontSize = 14
LTMHUDManage.lineSpacing = 3
LTMHUDManage.contentInset = 15
LTMHUDManage.iconSize = 36

// 2) Normal queued messages
HUDManage.showTitle("Saved")
HUDManage.showTitle("Saved in 2s", 2.0)
HUDManage.showInfo("Network unstable", 1.5)
HUDManage.showSuccess("Done")
HUDManage.showError("Request failed")

// 3) Priority (larger value shows earlier in pending queue)
HUDManage.showTitle("normal", 1.2, priority: 0)
HUDManage.showError("important", priority: 10)

// 4) Immediate interrupt of current HUD
HUDManage.showError("interrupt now", priority: 100, interruptCurrent: true)
HUDManage.showInfo("show now", 1.0, priority: 50, interruptCurrent: true)

// 5) Loading
HUDManage.showLoading() // default: "正在加载", timeout 60s
HUDManage.showLoading("Loading...")
HUDManage.showLoading("Syncing...", 15)
HUDManage.showLoading("Refresh token", nil, interruptCurrent: true)

// 6) Queue/lifecycle control
let pending = HUDManage.pendingCount // waiting count, excluding current HUD
HUDManage.dismiss()      // dismiss current, then continue queue
HUDManage.clearQueue()   // clear waiting queue only
HUDManage.dismissAll()   // dismiss current + clear waiting queue
```

Tips:
- `priority` only affects queue order; it does not interrupt current HUD.
- Use `interruptCurrent: true` only for urgent messages.
- Loading uses single-slot strategy: new loading replaces pending loading.
- Long text is auto-truncated (`...`) to stay inside screen bounds.

## Author

coenen, coenen@aliyun.com

## License

LTMSwift is available under the MIT license. See the LICENSE file for more info.
