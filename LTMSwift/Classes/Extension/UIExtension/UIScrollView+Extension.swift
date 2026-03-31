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
        let savedContentOffset = contentOffset
        let savedFrame = frame

        contentOffset = .zero
        frame = CGRect(x: 0, y: 0, width: contentSize.width, height: contentSize.height)
        defer {
            contentOffset = savedContentOffset
            frame = savedFrame
        }

        UIGraphicsBeginImageContextWithOptions(frame.size, false, UIScreen.main.scale)
        defer { UIGraphicsEndImageContext() }
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        layer.render(in: context)
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
