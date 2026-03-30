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

## Network 快速上手（自动刷新 + 自动重试）

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
            // 可选：全局开关
            config.enableAutoTokenRefresh = true
            config.maxAutoRetryCount = 1
            config.tokenRefreshTimeout = 8
            config.successStatusCodes = Set(200...299)

            // 可选：重复请求防护
            config.enableDuplicateRequestGuard = true
            config.duplicateRequestInterval = 0.5

            // 可选：日志配置（一次配置，全局生效）
            config.log.isEnabled = true
            config.log.logHeaders = true
            config.log.logBody = false
            config.log.maxBodyLogLength = 4000
            config.log.redactedKeys.insert("set-cookie")
            config.log.logger = { message in
                print(message)
            }

            // 可选：按 method/path 过滤可自动重试的请求
            config.autoRetryPathFilter = { method, path in
                // 例如：下单等接口不自动重试
                return !(method == "POST" && path.contains("/order/submit"))
            }

            // 判定是否 token 过期
            config.tokenExpiredMatcher = { raw in
                guard let dict = raw as? [String: Any] else { return false }
                return (dict["code"] as? String) == "403"
            }

            // token 刷新动作（single-flight）
            config.tokenRefreshAction = { done in
                // 刷新成功 done(true) -> 自动重放原请求
                // 刷新失败 done(false) -> 走 failureBlock
                done(true)
            }

            // 刷新失败统一处理
            config.onTokenRefreshFailed = { raw in
                print("refresh failed:", raw ?? "nil")
                // 可在这里统一登出/跳登录
            }

            // 可选：埋点事件
            config.networkEventHandler = { event in
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

业务侧调用示例：

```swift
NetworkManager.shared.meRequest(model: MeModel()) { result in
    guard let me = result as? MeModel else { return }
    print("me success:", me)
} failure: { error in
    print("me failed:", error ?? "nil")
}
```

说明：
- 响应字段映射可在 `applyConfig` 里一次配置（`codeKey` / `codeSuccess` / `dataKey`），所有 API 通用。
- `successStatusCodes` 用于配置 HTTP 成功码范围（默认 `200...299`）。
- `tokenRefreshTimeout` 可避免刷新动作未回调导致请求悬挂。
- `enableDuplicateRequestGuard` 可拦截 in-flight 或短时间重复请求。
- 日志配置也可在 `applyConfig` 统一设置，通过 `makeLogPlugin()` 注入各个 provider；可用 `log.logger` 接入业务日志系统，`log.maxBodyLogLength` 限制日志体长度。
- `request(...)` 内部仍然调用 Moya 的 `provider.request(...)`，只是额外封装了自动刷新与重试。
- 使用 `handleData(...)` / `failureHandle(data:)` 作为业务解析与错误映射统一入口。
- 配置 `tokenExpiredMatcher` + `tokenRefreshAction` 可启用刷新并重试；未配置时请求失败会直接回调。

Token 刷新失败统一处理模板：

```swift
config.onTokenRefreshFailed = { raw in
    // 1) 清理本地登录态
    // 2) 跳转登录页
    // 3) 上报事件（可携带 raw）
}
```

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
