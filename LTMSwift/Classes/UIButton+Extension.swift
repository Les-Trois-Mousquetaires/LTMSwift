//
//  UIButton+Extension.swift
//  LTMSwift
//
//  Created by 柯南 on 2022/11/29.
//

import Foundation
import UIKit

private var rectTopKey: UInt8 = 0
private var rectRightKey: UInt8 = 0
private var rectBottomKey: UInt8 = 0
private var rectLeftKey: UInt8 = 0

//MARK: - UIButton设置热区
public extension UIButton{
    /**
     设置热区
     
     - parameter top 顶部
     - parameter left 左边
     - parameter bottom 底部
     - parameter right 右边
     */
    func setEnlargeEdgeWith(top:CGFloat,
                            left:CGFloat,
                            bottom:CGFloat,
                            right:CGFloat){
        objc_setAssociatedObject(self, &rectTopKey, top, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        objc_setAssociatedObject(self, &rectRightKey, right, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        objc_setAssociatedObject(self, &rectBottomKey, bottom, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        objc_setAssociatedObject(self, &rectLeftKey, left, .OBJC_ASSOCIATION_COPY_NONATOMIC)
    }
    
    /**
     点击
     
     - parameter point 点击点
     - parameter event 响应
     */
    override func hitTest(_ point: CGPoint,
                               with event: UIEvent?) -> UIView? {
        if let topEdge = objc_getAssociatedObject(self, &rectTopKey) as? CGFloat,
           let rightEdge = objc_getAssociatedObject(self, &rectRightKey) as? CGFloat,
           let bottomEdge = objc_getAssociatedObject(self, &rectBottomKey) as? CGFloat,
           let leftEdge = objc_getAssociatedObject(self, &rectLeftKey) as? CGFloat {
            return CGRect(x: bounds.origin.x - leftEdge, y: bounds.origin.y - topEdge, width: bounds.width + leftEdge + rightEdge, height: bounds.height + topEdge + bottomEdge).contains(point) ? self : nil
        }
        return super.hitTest(point, with: event)
    }
}

//MARK: - UIButton设置图文位置间距
public extension UIButton {
    /// 逆时针方向🔄
    enum Position { case top, left, bottom, right }
    
    /**
     重置图片image与标题title位置(默认间距为0)
     */
    func imagePosition(_ position: Position, spacing: CGFloat = 0 ) {
        self.sizeToFit()
        
        let imageWidth: CGFloat = self.imageView?.image?.size.width ?? 0
        let imageHeight: CGFloat = self.imageView?.image?.size.height ?? 0
        
        let labelWidth: CGFloat = self.titleLabel?.frame.size.width ?? 0
        let labelHeight: CGFloat = self.titleLabel?.frame.size.height ?? 0
        
        switch position {
        case .top:
            imageEdgeInsets = UIEdgeInsets(top: -labelHeight - spacing / 2, left: 0, bottom: 0, right: -labelWidth)
            titleEdgeInsets = UIEdgeInsets(top: 0, left: -imageWidth, bottom: -imageHeight - spacing / 2, right: 0)
            break
            
        case .left:
            imageEdgeInsets = UIEdgeInsets(top: 0, left: -spacing / 2, bottom: 0, right: 0)
            titleEdgeInsets = UIEdgeInsets(top: 0, left: spacing * 1.5, bottom: 0, right: 0)
            break
            
        case .bottom:
            imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: -labelHeight - spacing / 2, right: -labelWidth)
            titleEdgeInsets = UIEdgeInsets(top: -imageHeight - spacing / 2, left: -imageWidth, bottom: 0, right: 0)
            break
            
        case .right:
            imageEdgeInsets = UIEdgeInsets(top: 0, left: labelWidth + spacing / 2, bottom: 0, right: -labelWidth - spacing / 2)
            titleEdgeInsets = UIEdgeInsets(top: 0, left: -imageWidth - spacing / 2, bottom: 0, right: imageWidth + spacing / 2)
            break
        }
    }
}

//MARK: - UIButton设置标题、颜色、图片
public extension UIButton {
    /**
     设置富文本标题
     */
    func setAttrTitle(_ attr: NSAttributedString){
        self.setAttributedTitle(attr, for: .normal)
        self.setAttributedTitle(attr, for: .selected)
        self.setAttributedTitle(attr, for: .highlighted)
    }
    
    /**
     设置背景图片
     */
    func setBackgroundImage(_ image: UIImage?){
        setBackgroundImage(image, for: .normal)
        setBackgroundImage(image, for: .selected)
        setBackgroundImage(image, for: .highlighted)
    }
    
    /**
     设置图片
     */
    func setImage(_ image: UIImage?){
        setImage(image, for: .normal)
        setImage(image, for: .selected)
        setImage(image, for: .highlighted)
    }
    
    /**
     设置标题
     */
    func setTitle(_ title: String?){
        setTitle(title, for: .normal)
        setTitle(title, for: .selected)
        setTitle(title, for: .highlighted)
    }
    /**
     设置标题颜色
     */
    func setTitleColor(_ color: UIColor?){
        setTitleColor(color, for: .normal)
        setTitleColor(color, for: .selected)
        setTitleColor(color, for: .highlighted)
    }
}
