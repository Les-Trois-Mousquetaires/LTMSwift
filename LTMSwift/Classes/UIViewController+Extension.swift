//
//  UIViewController+Extension.swift
//  LTMSwift
//
//  Created by 柯南 on 2023/1/11.
//

import UIKit

public extension UIViewController{
    /**
     隐藏系统返回按钮
     */
    func hiddenNavBackItem(){
        self.navigationController?.navigationItem.setHidesBackButton(true, animated: true)
        self.navigationItem.setHidesBackButton(true, animated: true)
        self.navigationController?.navigationBar.backItem?.setHidesBackButton(true, animated: true)
    }
    
    /**
     展示系统返回按钮
     */
    func showNavBackItem(){
        self.navigationController?.navigationItem.setHidesBackButton(false, animated: true)
        self.navigationItem.setHidesBackButton(false, animated: true)
        self.navigationController?.navigationBar.backItem?.setHidesBackButton(false, animated: true)
    }
    
}
