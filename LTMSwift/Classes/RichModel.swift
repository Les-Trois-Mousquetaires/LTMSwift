//
//  RichModel.swift
//  Alamofire
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
    public var lineSpace: CGFloat = 9
    /// 高度
    public var height: CGFloat = 44
    /// 视图类型
    public var type: RichItemType = .richLabel
    /// 默认白色
    public var cellColor: UIColor = .white
    /// 分割线颜色 默认灰色
    public var lineColor: UIColor = .gray
    
    /// 仅Textfield 是否可以输入
    public var isEnabled: Bool = true
    
    /// 仅Textfield  有效 且无value值
    public var placeHolder: NSMutableAttributedString = NSMutableAttributedString()
    /// Textfield 文本颜色 仅输入时有效
    public var textFieldTextColor: UIColor = .black
    /// Textfield 文本颜色 仅输入时有效
    public var textFieldFont: UIFont = .systemFont(ofSize: 14)
}
