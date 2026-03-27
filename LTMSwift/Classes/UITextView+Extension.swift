//
//  UITextView+Extension.swift
//  LTMSwift
//
//  Created by 柯南 on 2022/12/24.
//

import UIKit

private final class LTMTextViewObserverToken {
    private let token: NSObjectProtocol

    init(token: NSObjectProtocol) {
        self.token = token
    }

    deinit {
        NotificationCenter.default.removeObserver(token)
    }
}

public extension UITextView {
    
    private struct RuntimeKey {
        static var placeholderLabelKey: UInt8 = 0
        static var maxLengthKey: UInt8 = 0
        static var observerTokenKey: UInt8 = 0
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
        if let label = objc_getAssociatedObject(self, &RuntimeKey.placeholderLabelKey) as? UILabel {
            return label
        }

        if self.font == nil {
            self.font = UIFont.systemFont(ofSize: 14)
        }

        let label = UILabel(frame: self.bounds)
        label.numberOfLines = 0
        label.font = self.font
        label.textColor = .lightGray
        label.isUserInteractionEnabled = false
        addSubview(label)
        objc_setAssociatedObject(self, &RuntimeKey.placeholderLabelKey, label, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        setupTextChangeObserverIfNeeded()
        refreshPlaceholderVisibility()
        return label
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
    
    private func handleTextDidChange() {
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
        let insetBounds = bounds.inset(by: textContainerInset)
        let x = insetBounds.origin.x + textContainer.lineFragmentPadding
        let width = max(0, insetBounds.width - textContainer.lineFragmentPadding * 2)
        placeholderLabel.frame = CGRect(x: x, y: insetBounds.origin.y, width: width, height: insetBounds.height)
        placeholderLabel.isHidden = !(text?.isEmpty ?? true)
    }
    
    private func setupTextChangeObserverIfNeeded() {
        if objc_getAssociatedObject(self, &RuntimeKey.observerTokenKey) != nil {
            return
        }

        let token = NotificationCenter.default.addObserver(
            forName: UITextView.textDidChangeNotification,
            object: self,
            queue: .main
        ) { [weak self] _ in
            self?.handleTextDidChange()
        }
        let tokenBox = LTMTextViewObserverToken(token: token)
        objc_setAssociatedObject(self, &RuntimeKey.observerTokenKey, tokenBox, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}
