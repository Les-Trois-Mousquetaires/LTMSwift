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
