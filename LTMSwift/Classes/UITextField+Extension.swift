//
//  UITextField+Extension.swift
//  FBSnapshotTestCase
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

fileprivate var kAssociationKeyMaxLength: Int = 0
//MARK: - 设置最大长度
public extension UITextField{
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
        let indexEndOfText = prospectiveText.index(prospectiveText.startIndex, offsetBy: maxLength)
        let substring = prospectiveText[..<indexEndOfText]
        text = String(substring)
        selectedTextRange = selection
    }
}
