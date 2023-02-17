//
//  UISegmentedControl+Extension.swift
//  LTMSwift
//
//  Created by 柯南 on 2022/11/30.
//

import Foundation
public extension UISegmentedControl {
    /**
     设置Segment风格
     
     - parameter normalColor 默认颜色
     - parameter selectedColor 选中颜色
     - parameter dividerColor 分割线颜色
     */
    func setStyle(normalColor: UIColor, selectedColor: UIColor ,dividerColor: UIColor){
        let normalImage = UIImage.init(color: normalColor)
        let selectedImage = UIImage.init(color: selectedColor)
        let dividerImage = UIImage.init(color: dividerColor)
        setBackgroundImage(normalImage, for: .normal, barMetrics: .default)
        setBackgroundImage(selectedImage, for: .selected, barMetrics: .default)
        setDividerImage(dividerImage, forLeftSegmentState: .normal, rightSegmentState: .normal, barMetrics: .default)
        setTitleTextAttributes([NSAttributedString.Key.foregroundColor:normalColor,NSAttributedString.Key.font:UIFont.systemFont(ofSize: 14, weight: .medium)], for: .normal)
        setTitleTextAttributes([NSAttributedString.Key.foregroundColor:selectedColor,NSAttributedString.Key.font:UIFont.systemFont(ofSize: 14, weight: .medium)], for: .selected)
        self.layer.borderWidth = 2
        self.layer.cornerRadius = 5
        self.layer.borderColor = selectedColor.cgColor
        self.layer.masksToBounds = true
    }
}
