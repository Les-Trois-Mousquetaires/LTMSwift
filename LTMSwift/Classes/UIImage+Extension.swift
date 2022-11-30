//
//  UIImage+Extension.swift
//  LTMSwift
//
//  Created by 柯南 on 2022/11/29.
//

import Foundation
public extension UIImage{
    
    /**
     颜色生成图片
     
     - parameter color 色值
     */
    public class func createImage(_ color: UIColor)-> UIImage{
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
    public convenience init(color: UIColor) {
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
    public func addSlaveImage(slaveImage: UIImage) -> UIImage{
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

public extension UIImage{
    /**
     加载本地大图
     
     - parameter name 图片名
     */
    public class func largerImage(name: String) -> UIImage? {
        return self.largerImage(name: name, type: "png")
    }
    
    /**
     加载本地大图
     
     - parameter name 图片名
     - parameter type 图片类型
     
     - returns 大图
     */
    public class func largerImage(name: String, type: String) -> UIImage? {
        guard let path = Bundle.main.path(forResource: name, ofType: type) else {
            return UIImage()
        }
        
        return UIImage.init(contentsOfFile: path)
    }
}
