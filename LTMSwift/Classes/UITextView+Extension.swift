//
//  UITextView+Extension.swift
//  LTMSwift
//
//  Created by 柯南 on 2022/12/24.
//

import UIKit

public extension UITextView {
    
    private struct RuntimeKey {
        static var placeholderLabelKey: UInt8 = 0
        static var maxLengthKey: UInt8 = 0
        static var observerRegisteredKey: UInt8 = 0
    }
    /// 占位文字
    @IBInspectable var placeholder: String {
        get {
            return self.placeholderLabel.text ?? ""
        }
        set {
            self.placeholderLabel.text = newValue
            refreshPlaceholderVisibility()
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
            var label = objc_getAssociatedObject(self, &RuntimeKey.placeholderLabelKey) as? UILabel
            if label == nil {
                if self.font == nil {
                    self.font = UIFont.systemFont(ofSize: 14)
                }
                label = UILabel(frame: self.bounds)
                label?.numberOfLines = 0
                label?.font = self.font
                label?.textColor = .lightGray
                if let label {
                    addSubview(label)
                    objc_setAssociatedObject(self, &RuntimeKey.placeholderLabelKey, label, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                    sendSubviewToBack(label)
                }
                setupTextChangeObserverIfNeeded()
                refreshPlaceholderVisibility()
            }
            return label ?? UILabel()
        }
        set {
            objc_setAssociatedObject(self, &RuntimeKey.placeholderLabelKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    @IBInspectable var maxLength: Int {
        set {
            objc_setAssociatedObject(self, &RuntimeKey.maxLengthKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            setupTextChangeObserverIfNeeded()
            enforceMaxLengthIfNeeded()
        }get {
            if let length = objc_getAssociatedObject(self, &RuntimeKey.maxLengthKey) as? Int {
                return length
            } else {
                return Int.max
            }
        }
    }
    
    @objc private func handleTextDidChange() {
        enforceMaxLengthIfNeeded()
        refreshPlaceholderVisibility()
    }
    
    private func enforceMaxLengthIfNeeded() {
        guard let prospectiveText = text,
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
    
    private func refreshPlaceholderVisibility() {
        placeholderLabel.frame = bounds.inset(by: textContainerInset)
        placeholderLabel.isHidden = !(text?.isEmpty ?? true)
    }
    
    private func setupTextChangeObserverIfNeeded() {
        let isRegistered = (objc_getAssociatedObject(self, &RuntimeKey.observerRegisteredKey) as? Bool) ?? false
        guard !isRegistered else { return }
        NotificationCenter.default.addObserver(self, selector: #selector(handleTextDidChange), name: UITextView.textDidChangeNotification, object: self)
        objc_setAssociatedObject(self, &RuntimeKey.observerRegisteredKey, true, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}
