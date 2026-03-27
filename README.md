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
HUDManage.ltm_showtitle("Saved")
HUDManage.ltm_showtitle("Saved in 2s", 2.0)
HUDManage.ltm_showInfo("Network unstable", 1.5)
HUDManage.ltm_showSuccess("Done")
HUDManage.ltm_showError("Request failed")

// 3) Priority (larger value shows earlier in pending queue)
HUDManage.ltm_showtitle("normal", 1.2, priority: 0)
HUDManage.ltm_showError("important", priority: 10)

// 4) Immediate interrupt of current HUD
HUDManage.ltm_showError("interrupt now", priority: 100, interruptCurrent: true)
HUDManage.ltm_showInfo("show now", 1.0, priority: 50, interruptCurrent: true)

// 5) Loading
HUDManage.ltm_showLoading() // default: "正在加载", timeout 60s
HUDManage.ltm_showLoading("Loading...")
HUDManage.ltm_showLoading("Syncing...", 15)
HUDManage.ltm_showLoading("Refresh token", nil, interruptCurrent: true)

// 6) Queue/lifecycle control
let pending = HUDManage.ltm_pendingCount // waiting count, excluding current HUD
HUDManage.ltm_dismiss()      // dismiss current, then continue queue
HUDManage.ltm_clearQueue()   // clear waiting queue only
HUDManage.ltm_dismissAll()   // dismiss current + clear waiting queue
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
