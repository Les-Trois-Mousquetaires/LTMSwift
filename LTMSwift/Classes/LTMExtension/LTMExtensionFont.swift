//
//  LTMExtensionFont.swift
//  LTMSwift
//
//  Created by kenan0620 on 07/29/2020.
//  Copyright (c) 2020 kenan0620. All rights reserved.
//
import UIKit

public enum SystemFontWeight {
    case ultraLight
    case thin
    case light
    case regular
    case medium
    case semibold
    case bold
    case heavy
    case black
    
    @available(iOS 10.0, *)
    
    func systemWeight() ->UIFont.Weight{
        switch self {
        case .ultraLight:
            return UIFont.Weight.ultraLight
        case .thin:
            return UIFont.Weight.thin
        case .light:
            return UIFont.Weight.light
        case .regular:
            return UIFont.Weight.regular
        case .medium:
            return UIFont.Weight.medium
        case .semibold:
            return UIFont.Weight.semibold
        case .bold:
            return UIFont.Weight.bold
        case .heavy:
            return UIFont.Weight.heavy
        case .black:
            return UIFont.Weight.black
        }
    }
}

public extension UIFont {
    /**
     苹果字体
     
     - parameter size 字体大小
     - parameter weight 字体格式
     */
    class func appleFont(size: CGFloat = 16, weight: SystemFontWeight = .regular) -> UIFont!{
        return UIFont.systemFont(ofSize: size, weight: weight.systemWeight())
    }
}
