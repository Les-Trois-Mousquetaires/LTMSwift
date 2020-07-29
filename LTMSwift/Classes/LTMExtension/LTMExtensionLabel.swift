//
//  LTMExtensionLabel.swift
//  ZhiHuiKuangShan
//
//  Created by 柯南 on 2020/7/23.
//  Copyright © 2020 TianRui. All rights reserved.
//

import Foundation

extension UILabel{
    
    /**
     控制字间距
     
     - parameter text 文本内容
     */
    func spaceText(text: String){
        let fontSize = self.font.pointSize
        switch fontSize {
        case 12:
            self.attributedText = NSAttributedString.textSpace(text: text, space: 0.4)
        case 14:
            self.attributedText = NSAttributedString.textSpace(text: text, space: 0.5)
        case 16:
            self.attributedText = NSAttributedString.textSpace(text: text, space: 0.6)
        case 18:
            self.attributedText = NSAttributedString.textSpace(text: text, space: 0.7)
        case 20:
            self.attributedText = NSAttributedString.textSpace(text: text, space: 0.8)
            
        default:
            self.attributedText = NSAttributedString.textSpace(text: text, space: 0.5)
        }
    }
}
