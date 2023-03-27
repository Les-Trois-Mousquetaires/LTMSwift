//
//  UIScrollView+Extension.swift
//  LTMSwift
//
//  Created by 柯南 on 2023/3/27.
//

import UIKit

extension UIScrollView {
    
    /// 截长屏Image
    var captureLongImage: UIImage? {
        var image: UIImage? = nil
        let savedContentOffset = contentOffset
        let savedFrame = frame
        
        contentOffset = .zero
        frame = CGRect(x: 0, y: 0,
                       width: contentSize.width,
                       height: contentSize.height)
        
        UIGraphicsBeginImageContext(frame.size)
        UIGraphicsBeginImageContextWithOptions(
            CGSize(width: frame.size.width,
                   height: frame.size.height),
            false,
            UIScreen.main.scale)
        layer.render(in: UIGraphicsGetCurrentContext()!)
        image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        contentOffset = savedContentOffset
        frame = savedFrame

        return image
    }
}
