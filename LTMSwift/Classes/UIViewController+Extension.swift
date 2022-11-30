//
//  UIViewController+Extension.swift
//  FBSnapshotTestCase
//
//  Created by 柯南 on 2022/11/30.
//

import Foundation

extension UIViewController {
    
    /**
     系统拨打电话、固定电话
     
     - parameter phone 电话号码
     */
    func callPhone(_ phone: String) {
        var phoneStr = phone
        /// 小于固话长度
        if phone.count < 7{
            return
        }
        if phoneStr.count > 11 {
            phoneStr = phoneStr.deleteNullString()
        }
        // 在cell上 保证丝滑....
        DispatchQueue.main.async {
            let phoneUrlStr = "telprompt://" + phoneStr
            if UIApplication.shared.canOpenURL(URL(string: phoneUrlStr)!) {
                UIApplication.shared.open(URL(string: phoneUrlStr)!, options: [:], completionHandler: nil)
            }
        }
    }
}
