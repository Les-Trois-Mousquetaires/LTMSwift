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
