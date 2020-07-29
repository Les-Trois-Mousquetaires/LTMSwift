//
//  LTMExtensionAttributedString.swift
//  ZhiHuiKuangShan
//
//  Created by 柯南 on 2020/7/23.
//  Copyright © 2020 TianRui. All rights reserved.
//

import Foundation

extension NSAttributedString{
    /**
     设置字间距
     
     - parameter text 文本内容
     */
    class func textSpace(text: String) -> NSAttributedString{
        return NSAttributedString.textSpace(text: text, space: 0.5)
    }
    
    /**
     设置字间距
     
     - parameter text 文本内容
     - parameter space 字间距大小
     */
    class func textSpace(text: String, space: Double) -> NSAttributedString{
        return NSAttributedString(string: text,
                                  attributes: [NSAttributedString.Key.kern : space])
    }
    
    /**
     设置行间距
     
     - parameter text 文本内容
     */
    class func textLineSpace(text: String) -> NSAttributedString{
        let style = NSMutableParagraphStyle()
        style.lineSpacing = 105
        
        return NSAttributedString(string: text,
                                  attributes: [NSAttributedString.Key.paragraphStyle: style])
    }
    
    /**
     设置字间距及行间距
     
     - parameter text 文本内容
     - parameter space 字间距大小
     - parameter lineSpace 行间距大小
     
     */
    class func textLineSpace(text: String, space: Double, lineSpace: CGFloat) -> NSAttributedString{
        let style = NSMutableParagraphStyle()
        style.lineSpacing = lineSpace
        
        return NSAttributedString(string: text,
                                  attributes: [NSAttributedString.Key.paragraphStyle: style,
                                               NSMutableAttributedString.Key.kern: space])
    }
}
