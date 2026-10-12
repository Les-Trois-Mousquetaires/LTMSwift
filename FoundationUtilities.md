# 基础工具与版本管理

本模块提供可独立使用的数据工具与版本检查能力，不包含界面、品牌资源或业务流程。

## 目录终态

```text
LTMSwift/Classes/
├── Extension/BaseExtension/
│   ├── Sequence+Extension.swift
│   ├── Dictionary+Extension.swift
│   ├── Int+Extension.swift
│   └── Bundle+Extension.swift
└── Version/
    ├── VersionManager.swift
    └── VersionModel.swift
```

## 基础工具

通过 LTMSwift/Extension/BaseExtension 使用。

- toCompactDictionary：键值对集合转字典，忽略 nil，重复键以最后一个非 nil 值为准。
- filterNilValues：过滤顶层 nil、NSNull、空字符串、空数组及空字典；保留数字 0、布尔 false。递归去空值继续使用现有 removingNullValues。
- uppercaseChineseNumber：1...99 转中文数字，其余范围保留十进制文本。
- Bundle.appVersion / appBuild：读取接收者自身的版本信息，不强制使用主 Bundle。
- JSON 字典和数组序列化继续使用现有 toJSONString(prettyPrinted:)；字符串解析继续使用现有 jsonDictionary / jsonArray。未增加同名 JSON 重载。

## 版本管理

通过 LTMSwift/Version 使用，仅依赖 BaseExtension 和 Foundation。

```swift
let manager = VersionManager()
let newer = try manager.isNewVersion(storeVer: "2.0", localVer: "1.9.9")
let result = try await manager.checkUpdate(
    appId: "123456789",
    country: "us",
    localVersion: "1.0.0"
)
```

支持点分隔的非负数字版本，短版本补零，忽略前导零，按数字段长度及字典序比较以避免整数溢出。空版本、空数字段、负数和预发布后缀返回 invalidVersion，不把错误版本默认为正常版本。

checkUpdate 为 async throws，地区由调用方配置，默认 us；使用 URLComponents 构造查询。支持注入 URLSession 和 Bundle。无效参数、非成功 HTTP、未找到应用、网络和解码错误均传递给调用方。返回 VersionCheckModel，包含 needsUpdate、localVersion 和 storeInfo。不展示弹窗或自动打开商店，调用方根据结果决定操作。

## 边界

颜色、富文本 HTML 和文字尺寸测量不属于这次 Foundation 能力扩展。版本接口不接受业务模型，不绑定 UI 框架。新能力需随后续版本发布；现有接口可继续独立使用。

## 访问控制

VersionManager 为 public final，提供 public 初始化方法和查询接口，通过 URLSession 注入配置请求，无需继承。AppStoreInfoModel、VersionCheckModel 的字段和初始化方法公开，VersionError 公开供调用方捕获。AppStoreLookupModel 仅供模块内部解码，网络会话和版本段解析保持 private。基础工具使用 public extension，可由其他模块直接调用；没有需要跨模块覆写的类，因此不使用 open。
