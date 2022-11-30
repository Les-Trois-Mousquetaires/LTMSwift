//
//  UILabel+Extension.swift
//  LTMSwift
//
//  Created by 柯南 on 2022/11/29.
//

import Foundation
public extension UILabel{
    /**
     设置字间距
     
     - parameter text 文本内容
     - parameter textSpace 字间距大小
     */
    public func setTextSpace(text: String, textSpace: Double) {
        self.setTextSpace(text: text, textSpace: textSpace, lineSpace: 0)
    }
    
    /**
     设置行间距
     
     - parameter text 文本内容
     - parameter lineSpace 行间距大小
     */
    public func setTextSpace(text: String, lineSpace: CGFloat) {
        self.setTextSpace(text: text, textSpace: 0, lineSpace: lineSpace)
    }
    
    /**
     设置行间距和字间距
     
     - parameter text 文本内容
     - parameter textSpace 字间距大小
     - parameter lineSpace 行间距大小
     */
    public func setTextSpace(text: String, textSpace: Double, lineSpace: CGFloat) {
        self.attributedText = NSAttributedString.setTextSpaceAndLineSpace(text: text, textSpace: textSpace, lineSpace: lineSpace)
    }
}
