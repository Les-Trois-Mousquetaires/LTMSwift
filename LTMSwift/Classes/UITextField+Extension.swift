//
//  UITextField+Extension.swift
//  LTMSwift
//
//  Created by 柯南 on 2022/11/30.
//

import Foundation

public extension UITextField{
    /**
     设置UITextField字间距
     
     - parameter space 字间距大小
     */
    func space(space: CGFloat) {
        self.defaultTextAttributes = [NSAttributedString.Key.kern: space]
    }
}

/// 最大长度
fileprivate var kAssociationKeyMaxLength: Int = 0
/// 小数位 不允许0和空格开头
fileprivate var kAssociationKeyDigits: Int = 0
/// 最大值 不允许0和空格开头
fileprivate var kAssociationKeyMaxNumber: NSNumber = 0
/// 限制回调
fileprivate var kAssociationKeyLibmitBlock: String = "kAssociationKeyLibmitBlock"
//MARK: - 设置最大长度
public extension UITextField{
    /**
     输入框限制原因
     
     - parameter limitReason 触发限制的原因
    2:小数点开头 3:已输入小数点，再次输入小数点 4:小数位数超出限制 5:超过最大值限制，6:最大长度
     */
    @IBInspectable var limitBlock: ((_ limitReason: Int) -> Void)? {
        set {
            objc_setAssociatedObject(self, &kAssociationKeyLibmitBlock, newValue, .OBJC_ASSOCIATION_RETAIN)
        }get {
            if let block = objc_getAssociatedObject(self, &kAssociationKeyLibmitBlock) as? ((_ result: Int) -> Void)? {
                return block
            } else {
                return nil
            }
        }
    }
    /// 最大长度
    @IBInspectable var maxLength: Int {
        set {
            objc_setAssociatedObject(self, &kAssociationKeyMaxLength, newValue, .OBJC_ASSOCIATION_RETAIN)
            addTarget(self, action: #selector(checkMaxLength), for: .editingChanged)
        }get {
            if let length = objc_getAssociatedObject(self, &kAssociationKeyMaxLength) as? Int {
                return length
            } else {
                return Int.max
            }
        }
    }
    
    @objc func checkMaxLength(textField: UITextField) {
        guard let prospectiveText = self.text,
              prospectiveText.count > maxLength
        else {
            return
        }
        let selection = selectedTextRange
        if (prospectiveText.count > maxLength){
            if ((self.limitBlock) != nil){
                self.limitBlock!(6)
            }
        }
        let indexEndOfText = prospectiveText.index(prospectiveText.startIndex, offsetBy: maxLength)
        let substring = prospectiveText[..<indexEndOfText]
        text = String(substring)
        selectedTextRange = selection
    }
    
    /// 小数位
    @IBInspectable var digits: Int {
        set {
            objc_setAssociatedObject(self, &kAssociationKeyDigits, newValue, .OBJC_ASSOCIATION_RETAIN)
            addTarget(self, action: #selector(checkMaxDigits), for: .editingChanged)
        }get {
            if let digit = objc_getAssociatedObject(self, &kAssociationKeyDigits) as? Int {
                return digit
            } else {
                return Int.max
            }
        }
    }
    
    @objc func checkMaxDigits(textField: UITextField) {
        guard let prospectiveText = self.text
        else {
            return
        }
        /// 小数点开头不允许
        if (prospectiveText.hasPrefix(".")){
            self.text = ""
            guard let block = self.limitBlock else {
                return
            }
            block(2)
            return
        }
        if (prospectiveText.contains(".")){
            if (prospectiveText.findFirst(".") != prospectiveText.findLast(".") ){
                let selection = selectedTextRange
                let substring = prospectiveText.subString(to: prospectiveText.findLast("."))
                text = String(substring)
                selectedTextRange = selection
                guard let block = self.limitBlock else {
                    return
                }
                block(3)
            }else{
                if (prospectiveText.count > prospectiveText.findFirst(".") + digits){
                    let selection = selectedTextRange
                    let substring = prospectiveText.subString(to: prospectiveText.findFirst(".") + digits + 1)
                    text = String(substring)
                    selectedTextRange = selection
                    guard let block = self.limitBlock else {
                        return
                    }
                    block(4)
                }
            }
        }
    }
    
    /// 最大值
    @IBInspectable var maxNumber: NSNumber {
        set {
            objc_setAssociatedObject(self, &kAssociationKeyMaxNumber, newValue, .OBJC_ASSOCIATION_RETAIN)
            addTarget(self, action: #selector(checkMaxNumber), for: .editingChanged)
        }get {
            if let max = objc_getAssociatedObject(self, &kAssociationKeyMaxNumber) as? NSNumber {
                return max
            } else {
                return 999999999
            }
        }
    }
    
    @objc func checkMaxNumber(textField: UITextField) {
        guard var prospectiveText = self.text
        else {
            return
        }
        let lastContent: String = UserDefaults.standard.string(forKey: "UITextFieldLastContent") ?? ""
        let selection = selectedTextRange
        let result: NSDecimalNumber = NSDecimalNumber.init(string: prospectiveText)
        if (lastContent.count > prospectiveText.count){
            /// 删除操作
        }else{
            if (result.doubleValue > maxNumber.doubleValue){
                text = lastContent
                prospectiveText = lastContent
                if ((self.limitBlock) != nil){
                    self.limitBlock!(5)
                }
            }
        }
        selectedTextRange = selection
        UserDefaults.standard.set(prospectiveText, forKey: "UITextFieldLastContent")
    }
}
