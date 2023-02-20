//
//  MarginLabel.swift
//  LTMSwift
//
//  Created by 柯南 on 2023/2/20.
//

import Foundation

/**
 带边距的标签
 */
open class MarginLabel: UILabel {
    /// 边距设置
    public var textInset: UIEdgeInsets = .zero
    
    open override func textRect(forBounds bounds: CGRect, limitedToNumberOfLines numberOfLines: Int) -> CGRect {
        var rect: CGRect = super.textRect(forBounds: bounds.inset(by: textInset), limitedToNumberOfLines: numberOfLines)
        //根据edgeInsets，修改绘制文字的bounds
        rect.origin.x -= textInset.left
        rect.origin.y -= textInset.top
        rect.size.width += textInset.left + textInset.right
        rect.size.height += textInset.top + textInset.bottom
        return rect
    }
    
    open override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: textInset))
    }
}
