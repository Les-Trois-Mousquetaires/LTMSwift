//
//  UIViewController+Extension.swift
//  LTMSwift
//
//  Created by 柯南 on 2023/1/11.
//

import Foundation

public extension UIViewController{
    /// 获取根视图
    var rootVC: UIViewController? {
        let window = UIApplication.shared.windows.filter({ $0.isKeyWindow }).last

        return window?.rootViewController
    }
}
