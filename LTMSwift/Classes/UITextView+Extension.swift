//
//  UITextView+Extension.swift
//  LTMSwift
//
//  Created by 柯南 on 2022/12/24.
//

import Foundation

public extension UITextView {
    
    private struct RuntimeKey {
        static let extension_placeholderLabelKey = UnsafeRawPointer.init(bitPattern: "extension_placeholderLabelKey".hashValue)
        /// ...其他Key声明
    }
    /// 占位文字
    @IBInspectable var placeholder: String {
        get {
            return self.placeholderLabel.text ?? ""
        }
        set {
            self.placeholderLabel.text = newValue
        }
    }
    
    /// 占位文字颜色
    @IBInspectable var placeholderColor: UIColor {
        get {
            return self.placeholderLabel.textColor
        }
        set {
            self.placeholderLabel.textColor = newValue
        }
    }
    
    /// 占位文字字体
    @IBInspectable var placeholderFont: UIFont {
        get {
            return self.placeholderLabel.font
        }
        set {
            self.placeholderLabel.font = newValue
        }
    }
    
    private var placeholderLabel: UILabel {
        get {
            var label = objc_getAssociatedObject(self, UITextView.RuntimeKey.extension_placeholderLabelKey!) as? UILabel
            if label == nil { // 不存在是 创建 绑定
                if (self.font == nil) { // 防止没大小时显示异常 系统默认设置14
                    self.font = UIFont.systemFont(ofSize: 14)
                }
                label = UILabel.init(frame: self.bounds)
                label?.numberOfLines = 0
                label?.font = self.font
                label?.textColor = UIColor.lightGray
                self.addSubview(label!)
                self.setValue(label!, forKey: "_placeholderLabel")
                objc_setAssociatedObject(self, UITextView.RuntimeKey.extension_placeholderLabelKey!, label!, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                self.sendSubviewToBack(label!)
            }
            return label!
        }
        set {
            objc_setAssociatedObject(self, UITextView.RuntimeKey.extension_placeholderLabelKey!, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}


fileprivate var kAssociationKeyMaxLength: Int = 0
extension UITextView: UITextViewDelegate{
    @IBInspectable public var maxLength: Int {
        set {
            self.delegate = self
            objc_setAssociatedObject(self, &kAssociationKeyMaxLength, newValue, .OBJC_ASSOCIATION_RETAIN)
        }get {
            if let length = objc_getAssociatedObject(self, &kAssociationKeyMaxLength) as? Int {
                return length
            } else {
                return Int.max
            }
        }
    }
    
    public func textViewDidChange(_ textView: UITextView) {
        checkMaxLength(textField: self)
    }
    @objc func checkMaxLength(textField: UITextView) {
        guard let prospectiveText = self.text,
              prospectiveText.count > maxLength
        else {
            return
        }
        
        let selection = selectedTextRange
        let indexEndOfText = prospectiveText.index(prospectiveText.startIndex, offsetBy: maxLength)
        let substring = prospectiveText[..<indexEndOfText]
        text = String(substring)
        selectedTextRange = selection
    }
}
