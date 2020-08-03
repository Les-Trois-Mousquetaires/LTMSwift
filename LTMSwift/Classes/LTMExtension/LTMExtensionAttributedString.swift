//
//  LTMExtensionAttributedString.swift
//  LTMSwift
//
//  Created by kenan0620 on 07/29/2020.
//  Copyright (c) 2020 kenan0620. All rights reserved.
//
import Foundation

public extension NSAttributedString{
    /**
     设置字间距及行间距
     
     - parameter text 文本内容
     - parameter textSpace 字间距大小
     - parameter lineSpace 行间距大小
     
     - returns: 处理后的富文本
     */
    class func setTextSpaceAndLineSpace(text: String, textSpace: Double, lineSpace: CGFloat) -> NSAttributedString{
        let style = NSMutableParagraphStyle()
        style.lineSpacing = lineSpace
        
        return NSAttributedString(string: text,
                                  attributes: [NSAttributedString.Key.paragraphStyle: style,
                                               NSMutableAttributedString.Key.kern: textSpace])
    }
}
