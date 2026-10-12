# 公共请求参数插件

## 目录终态

```text
LTMSwift/Classes/Network/Plugin/
├── LTMLogPlugin.swift
└── NetworkParamPlugin.swift
```

通过 LTMSwift/Network 引入。NetworkParamPlugin 为 public final，相关编码、冲突策略和错误枚举公开；通过闭包配置，无需继承。

## 配置

```swift
let plugin = NetworkParamPlugin(
    queryProvider: { _ in ["clientVersion": "1.0"] },
    bodyProvider: { _ in ["platform": "ios", "retryCount": 0] },
    mergePolicy: .keepExisting,
    bodyEncoding: .automatic
)
```

queryProvider 与 bodyProvider 均可选，每次请求动态获取，可根据 TargetType 决定参数。URL 参数使用 String 字典，调用方明确转换数字和布尔值；URLComponents 处理百分号编码。JSON 支持合法对象，表单支持字符串、NSNumber、NSNull、数组和字符串键字典，数组与嵌套字典采用括号键。默认保留原参数，同名覆盖可选 replaceExisting。表单合并按根键处理，保留未冲突的重复数组值。

## Body 边界

automatic 根据 Content-Type 识别 application/json、+json 或 application/x-www-form-urlencoded。没有 Content-Type 时不推断，可显式指定 json 或 form。GET、HEAD、httpBodyStream、Multipart 和其他已声明的二进制类型不注入 Body。显式格式不会改变已经声明的其他格式。

非对象 JSON、非法 JSON、无效表单编码、非 JSON 参数及不支持的表单值会保持原 Body，可通过 errorHandler 接收错误；已成功添加的 Query 保留。编码完成后清除旧 Content-Length，交由 URLSession 计算。原方法、其他请求头、URL fragment 保持不变。

提供器与 errorHandler 在 Moya prepare 所在线程运行，库不强制切换主线程；调用方管理捕获对象的线程安全及生命周期。插件不预置设备、用户、令牌或业务字段，不改变目标请求的鉴权与签名规则。
