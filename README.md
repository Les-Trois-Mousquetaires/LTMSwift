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

## Network Module (Moya-based Wrapper)

This module is a Moya-based wrapper:

```text
Moya TargetType -> MoyaProvider -> LTMNetworkDeal.request(...) -> unified parse/retry/logging
```

### 1) Define Moya TargetType

```swift
import Foundation
import Moya

enum UserApi {
    case profile
    case updateNickname(String)
}

extension UserApi: TargetType {
    var baseURL: URL { URL(string: "https://api.example.com")! }

    var path: String {
        switch self {
        case .profile: return "/user/profile"
        case .updateNickname: return "/user/update"
        }
    }

    var method: Moya.Method {
        switch self {
        case .profile: return .get
        case .updateNickname: return .post
        }
    }

    var task: Task {
        switch self {
        case .profile:
            return .requestPlain
        case .updateNickname(let name):
            return .requestParameters(parameters: ["nickname": name], encoding: JSONEncoding.default)
        }
    }

    var headers: [String: String]? {
        ["Content-Type": "application/json"]
    }
}
```

### 2) Build NetworkManager with MoyaProvider

```swift
import LTMSwift
import Moya

final class NetworkManager: LTMNetworkDeal {
    static let shared = NetworkManager()

    private lazy var logPlugin = makeLogPlugin()
    private lazy var userProvider = MoyaProvider<UserApi>(plugins: [logPlugin])
    private lazy var authProvider = MoyaProvider<AuthApi>(plugins: [logPlugin])

    private override init() {
        super.init()

        applyConfig { config in
            // Response example from backend:
            // {
            //   "code": "200",
            //   "msg": "ok",
            //   "data": { "id": 42, "nickname": "LTM" }
            // }
            // Mapping:
            // - codeKey reads "code"
            // - successCodes matches "200"/"0" as business success
            // - dataKey points to "data" for model parsing
            // - successStatusCodes validates HTTP first (for example 200)
            config.response.codeKey = "code"
            config.response.successCodes = ["200", "0"]
            config.response.dataKey = "data"
            config.response.successStatusCodes = Set(200...299)

            // Callback dispatch behavior:
            // - true: dispatch success/failure on main thread (UI-friendly)
            // - false: keep current callback thread (data-processing friendly)
            config.callback.onMainThread = true

            // Observer example: receives refresh/retry/duplicate-block events
            config.observer.eventHandler = { event in
                print("network event:", event)
            }

            // Token refresh still uses Moya request internally
            // Failure payload example (business code 403): {"code":"403","msg":"token expired"}
            config.tokenRefresh.isEnabled = true      // Enables token-expired auto-refresh flow
            config.tokenRefresh.maxRetryCount = 1      // Max auto-retry count per request
            config.tokenRefresh.timeout = 8            // Refresh action timeout in seconds
            config.tokenRefresh.expiredMatcher = { raw in
                guard let dict = raw as? [String: Any] else { return false }
                return (dict["code"] as? String) == "403"
            }
            config.tokenRefresh.refreshAction = { [weak self] done in
                guard let self else { done(false); return }
                self.authProvider.request(.refreshToken) { result in
                    switch result {
                    case .success:
                        done(true)
                    case .failure:
                        done(false)
                    }
                }
            }
            config.tokenRefresh.pathFilter = { method, path in
                // Trigger scenario: a request matches token-expired condition (for example code 403)
                // Input example: method = "POST", path = "/auth/refresh"
                // Trigger result: false -> skip auto-retry and go to failure callback directly
                // Trigger result: true  -> allow replaying original request after refresh succeeds
                !(method == "POST" && path == "/auth/refresh")
            }
            config.tokenRefresh.onRefreshFailed = { raw in
                // Trigger scenario: refreshAction ends with done(false) or refresh timeout
                // Input example: raw = ["code": "403", "msg": "token expired"]
                // Trigger result: run unified fallback (clear auth state / redirect login / toast / tracking)
                print("refresh failed:", raw ?? "nil")
            }

            config.duplicateRequest.isEnabled = true      // Enables duplicate request protection
            config.duplicateRequest.minimumInterval = 0.5  // Default minimum interval in seconds
            config.duplicateRequest.keyProvider = { method, path, defaultKey in
                // Request example: POST /note/save
                // Input params: id=42&content=hello&timestamp=1719999999&nonce=abc&sign=xxxx
                // Goal: ignore timestamp/nonce/sign, keep id/content for duplicate checks
                // Extend as needed: timestamp/ts/_t/nonce/sign/signature/requestId/traceId
                let unstablePattern = "(timestamp|ts|_t|nonce|sign|signature|requestId|traceId)=[^&|]*"
                let sanitized = defaultKey.replacingOccurrences(
                    of: unstablePattern,
                    with: "",
                    options: .regularExpression
                )
                let compact = sanitized.replacingOccurrences(of: "&&", with: "&")

                // Result example:
                // before key: POST|/note/save|...|{"content":"hello","id":42,"nonce":"abc","sign":"xxxx","timestamp":1719999999}
                // after  key: POST|/note/save|...|{"content":"hello","id":42}
                return "\(method)|\(path)|\(compact)"
            }
            config.duplicateRequest.intervalProvider = { method, path, key in
                // Per-endpoint interval override:
                // - /order/submit: 10s (strong anti-duplication)
                // - /sms/send: 1s (anti-double-tap)
                // - /feed/refresh: 0s (allow pass-through)
                // Return nil to fallback to minimumInterval
                if method == "POST", path == "/order/submit" { return 10 }
                if method == "POST", path == "/sms/send" { return 1 }
                if key.contains("/feed/refresh") { return 0 }
                return nil
            }
            config.duplicateRequest.failureBuilder = { method, path in
                // Unified failure payload when blocked, easy for UI to recognize
                [
                    "error": "duplicate-request",
                    "message": "Please do not submit repeatedly",
                    "method": method,
                    "path": path
                ]
            }
            config.duplicateRequest.recordTTL = 120      // Completed-record retention in seconds
            config.duplicateRequest.maxRecordCount = 2000 // Completed-record cache limit

            // Log output example:
            // [Network][Request] POST https://api.example.com/user/update
            // [Network][Headers] {"Authorization":"***"}
            // [Network][Response] status=200 url=...
            config.log.isEnabled = true                // Master log switch
            config.log.logHeaders = true                // Print request/response headers
            config.log.logBody = false                  // Print body or not (production: as needed)
            config.log.maxBodyLogLength = 4000          // Truncate body logs above this length
            config.log.redactedKeys.formUnion(["authorization", "set-cookie"]) // Redact sensitive fields
            config.log.logger = { message in            // Custom logger (default is print)
                print(message)
                // Expected result: logs are printed in request lifecycle order, for example:
                // [Network][Request] POST https://api.example.com/user/update
                // [Network][Headers] {"Authorization":"***"}
                // [Network][Response] status=200 url=https://api.example.com/user/update
            }
        }
    }
}
```

### 2.0) Response Mapping Example

Backend response example:

```json
{
  "code": "200",
  "msg": "ok",
  "data": {
    "id": 42,
    "nickname": "LTM"
  }
}
```

Matching config:

```swift
config.response.codeKey = "code"
config.response.successCodes = ["200", "0"]
config.response.dataKey = "data"
config.response.successStatusCodes = Set(200...299)
```

Match flow:
- Step 1: HTTP status code must be in `successStatusCodes` (for example 200).
- Step 2: Read `response[codeKey]` (`code` in this example), and it must match `successCodes`.
- Step 3: On success, parse `response[dataKey]` first (`data` in this example).
- If `dataKey` is missing: fallback to parsing the whole response dictionary.
- If `code` does not match: go to failure callback, and `failureHandle` receives the whole response dictionary.

### 2.1) Full Configuration Field Reference

`config.response`

- `codeKey`: Business status-code key, for example `code`.
- `successCodes`: Business success code set, for example `["200", "0"]`.
- `dataKey`: Business payload key, for example `data`.
- `successStatusCodes`: Accepted HTTP success status-code set (default `200...299`).
- Data parsing behavior: once business code is considered successful, parser uses `response[dataKey]` first; if missing, it falls back to the whole response dictionary.
- Type note: current default model deserialization expects a dictionary (`[String: Any]`). If `dataKey` points to a non-dictionary payload (for example an array), default parsing returns `nil`; use array-model parsing in business code or override parsing logic.

`config.callback`

- `onMainThread`: Whether callbacks are dispatched on the main thread.

`config.observer`

- `eventHandler`: Network event observer callback for metrics/debugging/retry visibility.

`config.tokenRefresh`

- `isEnabled`: Enables token-refresh + auto-retry flow.
- `maxRetryCount`: Maximum auto-retry count per request.
- `expiredMatcher`: Determines whether a failure should be treated as token-expired.
- `refreshAction`: Refresh-token action; call `done(true/false)` when finished.
- `timeout`: Refresh action timeout in seconds.
- `pathFilter`: Method/path filter for retry eligibility.
- `onRefreshFailed`: Unified fallback callback when refresh fails.

`config.duplicateRequest`

- `isEnabled`: Enables duplicate-request protection.
- `minimumInterval`: Minimum interval for the same request fingerprint (default fallback value).
- `intervalProvider`: Per-request interval override provider; return `nil` to fallback to `minimumInterval`.
- `keyProvider`: Custom duplicate-request key generator.
- `failureBuilder`: Builds failure payload when a duplicate request is blocked.
- Practical tip: remove unstable keys in `keyProvider` (`timestamp`, `nonce`, `sign`, `traceId`), keep business keys (`id`, `content`).
- `recordTTL`: Retention time (seconds) for completed-request records.
- `maxRecordCount`: Maximum cached completed-request record count.

`config.log`

- `isEnabled`: Master switch for network logging. No log output when `false`.
- `logHeaders`: Controls whether request/response headers are printed.
- `logBody`: Controls whether request/response bodies are printed.
- `maxBodyLogLength`: Maximum body log length. Longer content is truncated.
- `redactedKeys`: Sensitive-key set for header/body masking (for example `authorization`, `token`, `cookie`).
- `logger`: Custom log output closure. Defaults to `print` when not set.

### 3) Model Definitions (Based on LTMModel)

```swift
import LTMSwift

struct ProfileModel: LTMModel {
    var id: Int = 0
    var nickname: String = ""
}

struct BaseModel: LTMModel {
    var msg: String = ""
}

// List recommendation: keep `data` as dictionary and put list inside it
struct ArticleModel: LTMModel {
    var id: Int = 0
    var title: String = ""
}

struct ArticleListModel: LTMModel {
    var list: [ArticleModel] = []
    var total: Int = 0
}
```

Notes:
- Current default parsing entry expects a dictionary (`[String: Any]`).
- If backend `data` is a raw array, prefer `data: { list: [...] }` then parse with `ArticleListModel`.

### 4) Business request wrappers

```swift
extension NetworkManager {
    func profile(
        model: ProfileModel,
        success: ((ProfileModel?) -> Void)?,
        failure: ((Any?) -> Void)?
    ) {
        request(
            provider: userProvider,
            target: .profile,
            model: model,
            successBlock: success,
            failureBlock: failure
        )
    }

    func updateNickname(
        _ nickname: String,
        model: BaseModel,
        success: ((BaseModel?) -> Void)?,
        failure: ((Any?) -> Void)?
    ) {
        request(
            provider: userProvider,
            target: .updateNickname(nickname),
            model: model,
            successBlock: success,
            failureBlock: failure
        )
    }
}
```

### 5) Call Site (Call + Response Example)

Call code:

```swift
NetworkManager.shared.profile(model: ProfileModel()) { profile in
    print("profile:", profile as Any)
} failure: { error in
    print("error:", error as Any)
}
```

Example backend response for this call:

```json
{
  "code": "200",
  "msg": "ok",
  "data": {
    "id": 42,
    "nickname": "LTM"
  }
}
```

How this maps to config:

```swift
config.response.codeKey = "code"                  // reads response["code"]
config.response.successCodes = ["200", "0"]      // business success values
config.response.dataKey = "data"                  // parses response["data"]
config.response.successStatusCodes = Set(200...299) // HTTP gate first
```

### 6) Notes

- `makeLogPlugin()` creates a Moya plugin backed by `config.log`.
- Duplicate-request records are bounded by `recordTTL` and `maxRecordCount`.
- This section uses only the new API groups: `response / callback / observer / tokenRefresh / duplicateRequest / log`.

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
