# LTMSwift

[English](README.md)

[![CI Status](https://img.shields.io/travis/kenan0620/LTMSwift.svg?style=flat)](https://travis-ci.org/kenan0620/LTMSwift)
[![Version](https://img.shields.io/cocoapods/v/LTMSwift.svg?style=flat)](https://cocoapods.org/pods/LTMSwift)
[![License](https://img.shields.io/cocoapods/l/LTMSwift.svg?style=flat)](https://cocoapods.org/pods/LTMSwift)
[![Platform](https://img.shields.io/cocoapods/p/LTMSwift.svg?style=flat)](https://cocoapods.org/pods/LTMSwift)

## 示例工程

克隆仓库后，先在 Example 目录执行 `pod install`，再运行示例工程。

## 安装

LTMSwift 支持通过 [CocoaPods](https://cocoapods.org) 安装：

```ruby
pod 'LTMSwift'
```

如仅使用部分模块：

```ruby
pod 'LTMSwift/Extension'
pod 'LTMSwift/Extension/UIExtension'
pod 'LTMSwift/Extension/BaseExtension'
```

## CoreDataManager 快速上手

```swift
import LTMSwift

let manager = CoreDataManager.shared

// 1) 设置你自己的 .xcdatamodeld 名称（不带扩展名）
manager.coreDataName = "AppModel"

// 2) 获取主/后台 context
let viewContext = manager.managerContext
let bgContext = manager.backgroundContext

// 3) 安全保存
manager.saveContent(viewContext)
manager.saveContent(bgContext)

// 4) 清空某个实体
manager.clearStorage(entityName: "UserEntity")
```

提示：`coreDataName` 必须和你项目中的 `.xcdatamodeld` 名称完全一致。

## KeyChain 快速上手

```swift
import LocalAuthentication
import LTMSwift

let key = "secure.token"

// 1) 基础读写
let ok = KeyChain.save(key: key, data: "token_value")
let value = KeyChain.getData(key: key)

// 2) 生物识别保护条目
let access = KeyChain.makeAccessControl(flags: [.biometryCurrentSet])
let options = KeyChainQueryOptions(
    service: "com.demo.auth",
    account: "token",
    accessControl: access,
    authenticationPrompt: "验证身份以读取安全令牌"
)

let saveStatus = KeyChain.saveStatus(key: key, data: "secure_token", options: options)
let read = KeyChain.getDataStatus(key: key, options: options)

if read.status == errSecSuccess {
    print("token:", read.value ?? "")
} else {
    print(KeyChain.statusMessage(read.status))
}

// 3) Codable 对象
struct Profile: Codable { let id: Int; let name: String }
_ = KeyChain.saveObject(key: "profile", object: Profile(id: 1, name: "LTM"))
let profile = KeyChain.getObject(key: "profile", as: Profile.self)
```

常见状态码：
- `errSecSuccess`：成功
- `errSecUserCanceled`：用户取消生物识别
- `errSecAuthFailed`：生物识别失败
- `errSecInteractionNotAllowed`：当前上下文不允许交互
- `errSecItemNotFound`：未找到条目
- `errSecNotAvailable`：服务或生物识别不可用

提示：排查问题建议使用 `saveStatus/getDataStatus/deleteStatus` + `KeyChain.statusMessage(_:)`。

### KeyChain 迁移说明

- 历史 `NSString` 归档数据会在首次读取成功后自动迁移。
- 推荐迁移方式：保持旧 key 不变，先用新接口读取一次，再通过 `saveStatus` 重写。
- 若历史数据格式可能混用，优先使用 `getDataStatus`，便于按状态码做重试/兜底。

### accessible 选型建议

| 场景 | 建议 `accessible` | 说明 |
| --- | --- | --- |
| 普通 token / 会话信息 | `kSecAttrAccessibleAfterFirstUnlock` | 首次解锁后可用，适合后台读取 |
| 高安全敏感数据 | `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` | 仅解锁时可访问，且不迁移到其他设备 |
| 需要随备份迁移 | `kSecAttrAccessibleWhenUnlocked` | 解锁可访问，可备份迁移 |
| 后台可用且仅本机 | `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` | 后台可读且不迁移 |

### 生物识别完整流程（保存 + 读取 + 成败判断）

```swift
import LocalAuthentication
import LTMSwift

let key = "bio.token"

// 1) 构建访问控制策略
let access = KeyChain.makeAccessControl(flags: [.biometryCurrentSet, .userPresence])

// 2) 配置查询参数
let context = LAContext()
context.localizedCancelTitle = "改用密码"

let options = KeyChainQueryOptions(
    service: "com.demo.secure",
    account: "login_token",
    accessControl: access,
    authenticationPrompt: "验证身份以读取安全令牌",
    authenticationContext: context
)

// 3) 保存并判断是否真正写入
let saveStatus = KeyChain.saveStatus(key: key, data: "token_123", options: options)
guard saveStatus == errSecSuccess else {
    print("保存失败:", KeyChain.statusMessage(saveStatus))
    // 例如 errSecAuthFailed / errSecInteractionNotAllowed / errSecParam
    return
}

// 4) 读取并按状态码判断生物识别结果
let readResult = KeyChain.getDataStatus(key: key, options: options)
switch readResult.status {
case errSecSuccess:
    print("读取成功:", readResult.value ?? "")
case errSecUserCanceled:
    print("用户取消了生物识别")
case errSecAuthFailed:
    print("生物识别失败")
case errSecInteractionNotAllowed:
    print("当前状态不允许弹出生物识别交互")
default:
    print("读取失败:", KeyChain.statusMessage(readResult.status))
}
```

### 生物识别行为说明

- 生物识别成功/失败体现在读写返回的状态码（如 `errSecSuccess` / `errSecAuthFailed` / `errSecUserCanceled`），不是 `makeAccessControl` 的返回值。
- `makeAccessControl(...)` 只负责生成 `SecAccessControl?` 策略对象；返回 `nil` 表示策略构建失败。
- `saveStatus == errSecSuccess` 才表示“确实保存成功”。
- 若在后台或禁止交互场景读取，常见为 `errSecInteractionNotAllowed`。

### 业务侧统一错误码处理模板

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
        // 用户主动取消，不弹错误，交给上层决定是否静默
        return .userCanceled

    case errSecInteractionNotAllowed:
        // 常见于 App 不在前台、当前时机不可交互，可稍后重试
        return .retryable("当前不可交互，请稍后重试")

    case errSecAuthFailed:
        // 生物识别失败，建议引导密码登录兜底
        return .fallbackToPassword("生物识别失败，请使用密码")

    case errSecItemNotFound:
        // 视业务场景而定：首次登录、数据已清理、需重新写入
        return .fallbackToPassword("未找到安全数据，请重新登录")

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
        authenticationPrompt: "验证身份以继续"
    )

    let result = KeyChain.getDataStatus(key: key, options: options)
    switch handleKeychainStatus(result.status, value: result.value) {
    case .success(let token):
        print("读取成功:", token)

    case .userCanceled:
        print("用户取消，不打断主流程")

    case .retryable(let tip):
        print("可重试:", tip)

    case .fallbackToPassword(let tip):
        print("走密码兜底:", tip)

    case .fatal(let msg):
        print("致命错误:", msg)
    }
}
```

建议：
- `errSecUserCanceled` 归类为“可预期行为”，避免全局错误弹窗。
- `errSecInteractionNotAllowed` 做延迟重试（如 300ms~1s）比立即失败更稳。
- `errSecAuthFailed` 建议限制重试次数，超过阈值直接切密码。

## Network 完整示例（基于 Moya 二次封装）

当前 Network 模块是基于 `Moya` 的业务封装：

```text
Moya TargetType -> MoyaProvider -> LTMNetworkDeal.request(...) -> 统一解析/重试/日志
```

模块职责拆分：

```text
Network/
  Config/
  Core/
  Plugin/
  Runtime/
```

### 1) 定义 Moya Target（TargetType）

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

### 2) 基于 MoyaProvider 封装 NetworkManager

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
            // Response 解析
            // 后端返回示例：
            // {
            //   "code": "200",
            //   "msg": "ok",
            //   "data": { "id": 42, "nickname": "LTM" }
            // }
            // 映射关系：
            // - codeKey 对应 "code"
            // - successCodes 命中 "200"/"0" 视为业务成功
            // - dataKey 对应 "data"，成功后解析该字段
            // - successStatusCodes 先校验 HTTP 状态码（如 200）
            config.response.codeKey = "code"
            config.response.successCodes = ["200", "0"]
            config.response.dataKey = "data"
            config.response.successStatusCodes = Set(200...299)

            // 回调线程
            // 示例：
            // - true：success/failure 回调切回主线程（适合 UI 直接刷新）
            // - false：保持当前回调线程（适合纯数据处理）
            config.callback.onMainThread = true

            // 可观测事件
            // 示例：可收到 token 刷新开始/结束、自动重试、重复请求拦截等事件
            config.observer.eventHandler = { event in
                print("network event:", event)
            }

            // Token 过期自动刷新（刷新动作本身也走 Moya）
            // 失败示例（业务 code 403）：{"code":"403","msg":"token expired"}
            config.tokenRefresh.isEnabled = true      // 开启 token 过期自动刷新链路
            config.tokenRefresh.maxRetryCount = 1      // 单请求最大自动重试次数
            config.tokenRefresh.timeout = 8            // 刷新动作超时时间（秒）
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
                // 触发场景：某个请求命中过期码（如 403）后，决定“是否允许自动重试”
                // 输入示例：method = "POST", path = "/auth/refresh"
                // 触发结果：返回 false -> 不自动重试，直接走失败回调（避免递归刷新）
                // 触发结果：返回 true  -> 允许在刷新成功后自动重放原请求
                !(method == "POST" && path == "/auth/refresh")
            }
            config.tokenRefresh.onRefreshFailed = { raw in
                // 触发场景：refreshAction 最终回调 done(false) 或刷新超时
                // 输入示例：raw = ["code": "403", "msg": "token expired"]
                // 触发结果：执行统一兜底（如清理登录态、跳转登录页、弹 Toast、埋点）
                print("refresh failed:", raw ?? "nil")
            }

            // 重复请求防护
            config.duplicateRequest.isEnabled = true      // 开启重复请求防护
            config.duplicateRequest.minimumInterval = 0.5  // 默认最小间隔（秒）
            config.duplicateRequest.keyProvider = { method, path, defaultKey in
                // 示例请求地址：POST /note/save
                // 示例入参：id=42&content=hello&timestamp=1719999999&nonce=abc&sign=xxxx
                // 目标：忽略 timestamp/nonce/sign，保留 id/content 参与去重
                // 可按业务继续扩展：timestamp/ts/_t/nonce/sign/signature/requestId/traceId
                let unstablePattern = "(timestamp|ts|_t|nonce|sign|signature|requestId|traceId)=[^&|]*"
                let sanitized = defaultKey.replacingOccurrences(
                    of: unstablePattern,
                    with: "",
                    options: .regularExpression
                )
                let compact = sanitized.replacingOccurrences(of: "&&", with: "&")

                // 结果示例：
                // 处理前 key: POST|/note/save|...|{"content":"hello","id":42,"nonce":"abc","sign":"xxxx","timestamp":1719999999}
                // 处理后 key: POST|/note/save|...|{"content":"hello","id":42}
                return "\(method)|\(path)|\(compact)"
            }
            config.duplicateRequest.intervalProvider = { method, path, key in
                // 按接口动态覆盖间隔：
                // - /order/submit: 10s（强防重）
                // - /sms/send: 1s（防连点）
                // - /feed/refresh: 0s（放行）
                // 返回 nil 时回退到 minimumInterval
                if method == "POST", path == "/order/submit" { return 10 }
                if method == "POST", path == "/sms/send" { return 1 }
                if key.contains("/feed/refresh") { return 0 }
                return nil
            }
            config.duplicateRequest.failureBuilder = { method, path in
                // 被拦截时返回统一错误结构，业务层可直接识别并提示
                [
                    "error": "duplicate-request",
                    "message": "请勿重复提交",
                    "method": method,
                    "path": path
                ]
            }
            config.duplicateRequest.recordTTL = 120      // 已完成请求记录保留时长（秒）
            config.duplicateRequest.maxRecordCount = 2000 // 已完成请求记录上限

            // 日志插件
            // 输出示例：
            // [Network][Request] POST https://api.example.com/user/update
            // [Network][Headers] {"Authorization":"***"}
            // [Network][Response] status=200 url=...
            config.log.isEnabled = true                // 日志总开关
            config.log.logHeaders = true                // 打印请求/响应 Header
            config.log.logBody = false                  // 是否打印 Body（生产建议按需）
            config.log.maxBodyLogLength = 4000          // Body 最大输出长度，超出截断
            config.log.redactedKeys.formUnion(["authorization", "set-cookie"]) // 敏感字段脱敏
            config.log.logger = { message in            // 自定义日志输出（不设置则默认 print）
                print(message)
                // 预期结果：控制台会按请求生命周期输出日志，例如：
                // [Network][Request] POST https://api.example.com/user/update
                // [Network][Headers] {"Authorization":"***"}
                // [Network][Response] status=200 url=https://api.example.com/user/update
            }
        }
    }
}
```

### 2.0) Response 返回示例与配置映射

后端返回示例：

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

对应配置：

```swift
config.response.codeKey = "code"
config.response.successCodes = ["200", "0"]
config.response.dataKey = "data"
config.response.successStatusCodes = Set(200...299)
```

命中规则：
- 第一步：HTTP 状态码需在 `successStatusCodes` 内（例如 200）。
- 第二步：读取 `response[codeKey]`，即上例中的 `code`，值需命中 `successCodes`。
- 第三步：成功后优先解析 `response[dataKey]`（上例是 `data` 字段）。
- 若 `dataKey` 不存在：回退解析整个响应字典。
- 若 `code` 不命中：进入失败回调，`failureHandle` 收到完整响应字典。

### 2.1) 全量配置字段说明

`config.response`

- `codeKey`：业务状态码字段名，例如 `code`。
- `successCodes`：业务成功状态码集合，例如 `["200", "0"]`。
- `dataKey`：业务数据字段名，例如 `data`。
- `successStatusCodes`：HTTP 成功状态码集合，默认 `200...299`。
- 数据解析行为：当业务码命中成功后，优先解析 `response[dataKey]`；若该字段不存在，则回退为解析整个响应字典。
- 类型注意：当前默认模型反序列化入口是字典（`[String: Any]`）。若 `dataKey` 对应值是数组等非字典结构，默认会解析失败并返回 `nil`，建议在业务层改用数组模型解析或覆写解析逻辑。

`config.callback`

- `onMainThread`：回调是否切回主线程；UI 场景通常建议 `true`。

`config.observer`

- `eventHandler`：网络事件监听回调，用于埋点、调试、观测重试/刷新过程。

`config.tokenRefresh`

- `isEnabled`：是否启用 token 过期自动刷新与自动重试。
- `maxRetryCount`：单请求最大自动重试次数。
- `expiredMatcher`：判断失败结果是否属于 token 过期。
- `refreshAction`：执行刷新 token 的动作，完成后回调 `done(true/false)`。
- `timeout`：刷新动作超时时间（秒），超时后按失败处理。
- `pathFilter`：按 `method/path` 过滤哪些请求允许自动重试。
- `onRefreshFailed`：刷新失败后的统一兜底回调（如清理登录态、跳登录页）。

`config.duplicateRequest`

- `isEnabled`：是否启用重复请求防护。
- `minimumInterval`：同一请求指纹最小触发间隔（默认兜底值）。
- `intervalProvider`：按请求动态覆盖间隔；返回 `nil` 时回退 `minimumInterval`。
- `keyProvider`：自定义请求去重 key 生成规则。
- `failureBuilder`：重复请求被拦截时的失败结果构造器。
- 实战建议：在 `keyProvider` 中移除易变字段（如 `timestamp`、`nonce`、`sign`、`traceId`），保留业务字段（如 `id`、`content`）。
- `recordTTL`：已完成请求记录保留时长（秒）。
- `maxRecordCount`：已完成请求记录最大缓存条数。

`config.log`

- `isEnabled`：是否启用网络日志总开关；`false` 时不输出任何日志。
- `logHeaders`：是否打印请求/响应 Header。
- `logBody`：是否打印请求/响应 Body。
- `maxBodyLogLength`：Body 日志最大输出长度，超出会截断，避免大对象刷屏。
- `redactedKeys`：敏感字段脱敏键集合（如 `authorization`、`token`、`cookie`）。
- `logger`：自定义日志输出闭包；不设置时使用默认输出（`print`）。

### 3) 模型定义（基于 LTMModel）

```swift
import LTMSwift

struct ProfileModel: LTMModel {
    var id: Int = 0
    var nickname: String = ""
}

struct BaseModel: LTMModel {
    var msg: String = ""
}

// 列表建议：让 data 始终是字典，再在字典里放 list
struct ArticleModel: LTMModel {
    var id: Int = 0
    var title: String = ""
}

struct ArticleListModel: LTMModel {
    var list: [ArticleModel] = []
    var total: Int = 0
}
```

说明：
- 当前默认解析入口是字典（`[String: Any]`）。
- 若后端 `data` 直接返回数组，建议改为 `data: { list: [...] }` 再用 `ArticleListModel` 解析。

### 4) 业务请求封装

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

### 5) 业务调用（调用示例 + 返回示例）

调用代码：

```swift
NetworkManager.shared.profile(model: ProfileModel()) { profile in
    print("profile:", profile as Any)
} failure: { error in
    print("error:", error as Any)
}
```

该调用对应的后端返回示例：

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

上述返回与配置关系：

```swift
config.response.codeKey = "code"                  // 读取 response["code"]
config.response.successCodes = ["200", "0"]      // 命中则判定业务成功
config.response.dataKey = "data"                  // 成功后解析 response["data"]
config.response.successStatusCodes = Set(200...299) // HTTP 先过这一层
```

### 6) 可观测事件

`config.observer.eventHandler` 可收到：

- `autoRetrySkipped(reason:method:path:retryCount:)`
- `tokenRefreshStarted(method:path:retryCount:)`
- `tokenRefreshFinished(success:method:path:)`
- `requestRetried(method:path:retryCount:)`
- `duplicateRequestBlocked(reason:method:path:)`

### 7) 容量与性能说明

- 重复请求防护不会无限增长：`recordTTL` + `maxRecordCount` 双限制。
- `makeLogPlugin()` 生成的 Moya 插件复用同一套 `config.log` 配置。
- 本章节示例仅保留新设计字段（`config.response / callback / observer / tokenRefresh / duplicateRequest / log`）。

## Extension 快速上手（按文件）

### BaseExtension

#### `Dictionary+Extension.swift`

```swift
let raw: [String: Any] = ["name": "LTM", "ext": NSNull()]
let cleaned = raw.removingNullValues()
let json = cleaned.jsonString
```

提示：`jsonString` 是可选值，上传或存储前建议判空。

#### `Array+Extension.swift`

```swift
let array = [1, 2, 3]
let json = array.jsonString
```

提示：`toJSONString(prettyPrinted: true)` 适合日志调试。

#### `String+Extension.swift`

```swift
let json = "{\"name\":\"LTM\"}"
let obj = json.jsonDictionary
```

提示：非法 JSON 会返回 `nil`。

#### `String+Encryption.swift`

```swift
let encoded = "LTMSwift".base64Encoded
let decoded = encoded?.base64Decoded
```

#### `String+Extension.swift`（随机字符串）

```swift
let token = String.random(length: 16, includeNumbers: true)
```

### UIExtension

#### `UIControl+Extension.swift`

```swift
import LTMSwift

// 建议在 App 启动后调用一次
UIControl.enableGlobalDebounce()

// 单控件间隔
button.ltmDebounceInterval = 1.0
switchControl.ltmDebounceInterval = 0.5

// 关闭单个控件防抖
button.ltmDebounceInterval = 0
```

提示：`UIButton` 默认间隔 `1.0s`，其他 `UIControl` 默认 `0`（不拦截）。

#### `UIGestureRecognizer+Debounce.swift`

```swift
imageView.addDebouncedTapGesture(interval: 1.0, target: self, action: #selector(onTapImage))
label.addDebouncedTapGesture(interval: 0.8, target: self, action: #selector(onTapLabel))

@objc private func onTapImage() {}
@objc private func onTapLabel() {}
```

提示：仅对该手势生效，不影响你手动添加的其他手势。

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

提示：`maxLength`、`digits`、`maxNumber` 可叠加使用。

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

提示：如未匹配到新机型，可用 `UIDevice.current.detailedModel` 兜底显示。

#### `LTMHUDManage.swift`

```swift
// 访问方式
// UIViewController / UIView 中都可以直接 HUDManage.xxx(...)

// 1) 全局配置（建议在 App 启动时设置一次）
LTMHUDManage.isReceiveEvent = false // false: 阻断点击，true: HUD 显示时可继续点击
LTMHUDManage.maxQueueCount = 20
LTMHUDManage.deduplicateInterval = 0.8
LTMHUDManage.overflowStrategy = .dropOldest // 或 .dropNewest

// 样式
LTMHUDManage.maxTextWidth = UIScreen.main.bounds.width - 100
LTMHUDManage.labelFontSize = 14
LTMHUDManage.lineSpacing = 3
LTMHUDManage.contentInset = 15
LTMHUDManage.iconSize = 36

// 2) 普通排队提示
HUDManage.showTitle("已保存")
HUDManage.showTitle("2秒后消失", 2.0)
HUDManage.showInfo("网络不稳定", 1.5)
HUDManage.showSuccess("完成")
HUDManage.showError("请求失败")

// 3) 优先级队列（值越大越早展示）
HUDManage.showTitle("普通提示", 1.2, priority: 0)
HUDManage.showError("重要错误", priority: 10)

// 4) 立即打断当前 HUD
HUDManage.showError("立即打断", priority: 100, interruptCurrent: true)
HUDManage.showInfo("马上展示", 1.0, priority: 50, interruptCurrent: true)

// 5) Loading
HUDManage.showLoading() // 默认: "正在加载", 超时 60s
HUDManage.showLoading("加载中...")
HUDManage.showLoading("正在同步...", 15)
HUDManage.showLoading("刷新 token", nil, interruptCurrent: true)

// 6) 队列/生命周期控制
let pending = HUDManage.pendingCount // 等待队列数量（不含当前 HUD）
HUDManage.dismiss()      // 关闭当前，继续下一个
HUDManage.clearQueue()   // 只清空等待队列
HUDManage.dismissAll()   // 关闭当前 + 清空等待队列
```

提示：
- `priority` 只影响队列排序，不会打断当前 HUD。
- 只有传 `interruptCurrent: true` 才会立即打断。
- loading 采用单槽策略：新的 loading 会覆盖等待中的旧 loading。
- 长文本会自动截断（`...`），确保不会超出屏幕。

## 作者

coenen, coenen@aliyun.com

## License

LTMSwift 基于 MIT 协议开源，详见 LICENSE。
