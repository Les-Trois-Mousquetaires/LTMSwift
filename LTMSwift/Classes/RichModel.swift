//
//  RichModel.swift
//  LTMSwift
//
//  Created by zsn on 2022/12/4.
//

import Foundation

/// 富文本类型
public enum RichItemType {
    /// 输入框
    case textfield
    /// 富文本
    case richLabel
    /// 富文本加图片
    case richLabelImage
    /// 开关
    case textSwitch
}

//MARK: - 双富文本模型
public class RichModel{
    public init() {
        
    }
    /// 键
    public var key: NSMutableAttributedString = NSMutableAttributedString()
    /// 值
    public var value: NSMutableAttributedString = NSMutableAttributedString()
    /// 是否展示分割线
    public var isShowLine: Bool = true
    /// 响应键值
    public var eventKey: String = ""
    /// 是否展示更新分割线位置
    public var isUpdateLineSpace: Bool = false
    /// 分割线位置
    public var lineSpace: CGFloat = 14
    /// 标题左间距
    public var space: CGFloat = 14
    /// 高度
    public var height: CGFloat = 44
    /// 视图类型
    public var type: RichItemType = .richLabel
    /// 默认白色
    public var cellColor: UIColor = .white
    /// 分割线颜色 默认灰色
    public var lineColor: UIColor = .gray
}

/// 富文本模型
public class RichLabelModel: RichModel {
    /// 标题宽度
    public var titleWidth: CGFloat = 0
    
    public override init() {
        super.init()
        self.type = .richLabel
    }
}

/// 输入框模型
public class RichTextFieldModel: RichModel {
    /// 是否可以输入
    public var isEnabled: Bool = true
    /// 键盘
    public var keyboard: UIKeyboardType = .default
    /// 占位文本
    public var placeHolder: NSMutableAttributedString = NSMutableAttributedString()
    /// 文本颜色
    public var textFieldTextColor: UIColor = .black
    /// 字体
    public var textFieldFont: UIFont = .systemFont(ofSize: 14)
    /// 最大值
    public var maxNumber: NSNumber = -1
    /// 小数位
    public var digits: Int = -1
    /// 最大长度
    public var maxLength: Int = -1
    /// 限制回调
    public var limitBlock: ((_ limitReason: Int) -> Void)?
    
    public override init() {
        super.init()
        self.type = .textfield
    }
}

/// 富文本加图片模型
public class RichLabelImageModel: RichLabelModel {
    /// 图片名称
    public var imageName: String = ""
    /// 图片
    public var imageSize: CGSize = CGSize(width: 24, height: 24)
    /// 图片文本间距
    public var textImageSpace: CGFloat = 4
    /// 图片右间距
    public var rightSpace: CGFloat = 6
    
    public override init() {
        super.init()
        self.type = .richLabelImage
    }
}
/// 开关模型
public class RichTextSwitchModel: RichModel {
    /// 开关透明度
    public var alpha: CGFloat = 1
    /// 开关是否有用
    public var isEnabled: Bool = true
    /// 设置开关状态
    public var status: Bool = false
    /// 震动
    public var hasShake: Bool = true
    /// 开的背景颜色
    public var onTintColor: UIColor = .green
    /// 开的字体颜色
    public var onTextColor: UIColor = .white
    /// 开的文字
    public var onText: String = "是"
    /// 关的背景颜色
    public var offTintColor: UIColor = .gray
    /// 关的字体颜色
    public var offTextColor: UIColor = .white
    /// 关的文字
    public var offText: String = "否"
    /// 开关的字号
    public var textFont: UIFont = .systemFont(ofSize: 14, weight: .regular)
    /// 开关圆形部位的颜色
    public var thumbTintColor: UIColor = .white
    
    public override init() {
        super.init()
        self.type = .textSwitch
    }
}
