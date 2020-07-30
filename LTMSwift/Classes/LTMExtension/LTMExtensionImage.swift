//
//  LTMExtensionImage.swift
//  LTMSwift
//
//  Created by kenan0620 on 07/29/2020.
//  Copyright (c) 2020 kenan0620. All rights reserved.
//
import UIKit

extension UIImage{
    
    /**
     颜色生成图片
     
     - parameter color 色值
     */
    class func createImage(_ color: UIColor)-> UIImage{
        let rect = CGRect.init(x: 0.0, y: 0.0, width: 1.0, height: 1.0)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(color.cgColor)
        context?.fill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image!
    }
    
    /**
     用颜色生成图片
     
     - parameter color 色值
     */
    convenience init(color: UIColor) {
        let rect = CGRect.init(x: 0.0, y: 0.0, width: 1.0, height: 1.0)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(color.cgColor)
        context?.fill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        self.init(cgImage: (image!.cgImage)!)
    }
    
    /**
     图片拼接
     
     - parameter slaveImage 拼接图片
     */
    func addSlaveImage(slaveImage: UIImage) -> UIImage{
        var size = CGSize()
        size.width = self.size.width
        size.height = self.size.height + slaveImage.size.height
        UIGraphicsBeginImageContextWithOptions(size, true, 0.0)
        self.draw(in: CGRect(origin: CGPoint(x: 0,y :0), size: CGSize(width: self.size.width, height: self.size.height)))
        slaveImage.draw(in: CGRect(origin: CGPoint(x: 0,y :self.size.height), size: CGSize(width: self.size.width, height: slaveImage.size.height)))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image!
    }
}
