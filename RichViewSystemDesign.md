# RichView 架构与使用

LTMSwift 0.8.5 起最低支持 iOS 15.0。

## 范围与目录终态

RichView 提供富文本表单行、分组背景、阴影和可自定义 Header 的列表组件。本文说明组件职责、公共接口和布局约束。

```text
LTMSwift/Classes/UI/RichView/
├── RichListView.swift
├── RichModel.swift
├── RichLabelTVCell.swift
├── RichLabelImageTVCell.swift
├── RichTextFieldTVCell.swift
└── RichTextSwitchTVCell.swift
```

## 列表接口

model 保留旧单组配置；groups 过滤空组并启用独立分组背景。groupTitles 和 groupHeaderProvider 按过滤后的分组顺序对应，后者优先且需要每组独立视图。自定义 Header 及 headerView/footerView 必须提供完整 Auto Layout 高度约束，异步内容变化后调用 refreshAccessoryLayout。

默认禁用内部滚动，总高度包含行、分组头、间距、表头和表尾；开启 isScrollEnabled 后列表由父布局决定视口高度。容器完成约束布局后再测量列表宽度、更新分组背景坐标，滚动时转换行坐标到背景容器。分组阴影仅覆盖行区域，不含分组 Header。

setGroupShadow 更新已有背景样式，不重新加载 Cell 或创建 Header。透明度限制在 0...1，模糊半径不小于 0。阴影默认关闭。reloadRowData 检查索引和当前表格结构，结构变化时回退完整刷新。

## Cell 配置与复用

四种 Cell 的样式初始化入口公开。每次配置重设分割线缩进，避免复用残留。输入框配置先移除旧的限制事件，再按新模型安装有效限制，同时重设限制回调、字体和颜色。图片行应用 space、titleWidth、imageSize、textImageSpace、rightSpace。

组模式清除 Cell 背景色，统一使用 groupBackgroundColor；旧 model 模式继续使用行模型 cellColor。复杂 Header 内容高度、切换宽度和输入复用需运行验证，静态解析不等同于完整编译或 UI 验证。

分组圆角统一使用 groupCornerRadius，默认 10 点，负值按 0 处理。radius 仅用于旧 model 模式的 TableView 圆角；groups 模式通过 groupCornerRadius 配置背景圆角。setGroupShadow 的 radius 参数仍表示阴影模糊半径，默认 6，不控制圆角。

内部容器留白统一命名 contentInsets，默认 .zero；旧 edges 标记弃用并转发至 contentInsets，布局语义保持不变。

## 一次性分组配置

setGroups(_:titles:) 将原始分组和标题作为一组配置提交，过滤空组时同步过滤对应标题，只刷新一次。普通 groups/groupTitles 属性保留，分别配置时标题仍按过滤后的分组顺序对应。groupHeaderProvider 接收过滤后的索引。带标题分组建议使用 setGroups；无标题分组可以直接配置 groups。

宽度变化仅在存在自定义分组 Header 时重新加载 Cell，普通标题和无标题页面更新约束及背景即可。背景 frame 和 shadowPath 更新关闭隐式动画，避免滚动中的阴影拖尾。局部刷新去重索引，空索引不刷新行。

## 布局模式与使用约束

| 场景 | 配置 | 父布局职责 |
|---|---|---|
| 嵌入式列表 | isScrollEnabled = false（默认） | 约束宽度和位置，由内容推导高度 |
| 独立滚动列表 | isScrollEnabled = true | 约束列表视口宽度和高度 |
| 带标题分组 | setGroups(_:titles:) | 标题与原始分组索引对应 |
| 自定义分组头 | groupHeaderProvider | 提供独立视图及完整高度约束 |

contentInsets 为内层容器留白，避免与父布局的间距重复设置。阴影按需通过 setGroupShadow 启用，默认分组圆角 10。四种 Cell 使用模型中的固定行高；自定义 Header 通过约束自适应。分组背景常驻，不按可见区域复用，适用于少量分组的表单或信息列表。

## 使用示例

```swift
let listView = RichListView()
listView.isScrollEnabled = true
listView.contentInsets = UIEdgeInsets(top: 14, left: 14, bottom: 14, right: 14)
listView.setGroupShadow()
let firstItem = RichLabelModel()
firstItem.key = NSMutableAttributedString(string: "名称")
firstItem.value = NSMutableAttributedString(string: "示例")
firstItem.isShowLine = false

let secondItem = RichLabelModel()
secondItem.key = NSMutableAttributedString(string: "状态")
secondItem.value = NSMutableAttributedString(string: "可用")
secondItem.isShowLine = false

listView.setGroups([[firstItem], [secondItem]], titles: ["基本信息", "其他信息"])
```

自定义分组头示例：

```swift
listView.groupHeaderProvider = { [weak self] section in
    self?.makeHeader(section: section)
}
```

默认嵌入模式让父布局由内容高度推导列表高度；滚动模式需要父布局约束列表视口高度。Header 闭包如访问所属控制器应弱引用捕获。自定义 Header 默认在阴影卡片外，需和行共用卡片的布局不属于当前接口。
