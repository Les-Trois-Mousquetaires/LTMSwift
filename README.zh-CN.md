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

## 作者

coenen, coenen@aliyun.com

## License

LTMSwift 基于 MIT 协议开源，详见 LICENSE。
