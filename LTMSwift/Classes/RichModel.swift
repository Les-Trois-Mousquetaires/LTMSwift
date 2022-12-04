//
//  RichModel.swift
//  Alamofire
//
//  Created by zsn on 2022/12/4.
//

import Foundation

public enum RichItemType {
    /// 输入框
    case textfield
    /// 富文本
    case richLabel
}

//MARK: - 双富文本模型
open class RichModel: NSObject{
    override init() {
        
    }
    /// 键
    var key: NSMutableAttributedString = NSMutableAttributedString()
    /// 值
    var value: NSMutableAttributedString = NSMutableAttributedString()
    /// 是否展示分割线
    var isShowLine: Bool = true
    /// 响应键值
    var eventKey: String = ""
    /// 是否展示更新分割线位置
    var isUpdateLineSpace: Bool = false
    /// 分割线位置
    var lineSpace: CGFloat = 9
    /// 高度
    var height: CGFloat = 44
    /// 视图类型
    var type: RichItemType = .richLabel
    /// 默认白色
    var cellColor: UIColor = .white
    /// 分割线颜色 默认灰色
    var lineColor: UIColor = .gray
    
    /// 仅Textfield  有效 且无value值
    var placeHolder: NSMutableAttributedString = NSMutableAttributedString()
    /// Textfield 文本颜色 仅输入时有效
    var textFieldTextColor: UIColor = .black
    /// Textfield 文本颜色 仅输入时有效
    var textFieldFont: UIFont = .systemFont(ofSize: 14)
}
