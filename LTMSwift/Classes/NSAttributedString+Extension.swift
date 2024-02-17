//
//  NSAttributedString+Extension.swift
//  LTMSwift
//
//  Created by 柯南 on 2022/11/29.
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
    
    /**
     计算富文本的高度
     
     - parameter width: 最大宽度
     */
    @discardableResult
    func getHeight(_ width : CGFloat) -> CGFloat {
        let rect = self.boundingRect(with: CGSize.init(width: width, height: CGFloat(MAXFLOAT)), options: .usesLineFragmentOrigin, context: nil)
        
        return rect.size.height
    }
    
    /**
     计算富文本的宽度
     
     - parameter height: 最大高度
     */
    @discardableResult
    func getWidth(_ height: CGFloat) -> CGFloat {
        let rect = self.boundingRect(with: CGSize.init(width: CGFloat(MAXFLOAT), height: height), options: NSStringDrawingOptions.usesLineFragmentOrigin, context: nil)
        
        return rect.size.width
    }
}
