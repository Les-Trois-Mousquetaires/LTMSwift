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
    class func createImage(_ color: UIColor)-> UIImage{
        let render = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1))
        return render.image { context in
            color.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        }
    }
    
    /**
     用颜色生成图片
     
     - parameter color 色值
     */
    convenience init(color: UIColor) {
        let image = Self.createImage(color)
        if let cgImage = image.cgImage {
            self.init(cgImage: cgImage)
        } else {
            self.init()
        }
    }
    
    /**
     图片拼接
     
     - parameter slaveImage 拼接图片
     */
    func addSlaveImage(slaveImage: UIImage) -> UIImage{
        let size = CGSize(width: self.size.width, height: self.size.height + slaveImage.size.height)
        let render = UIGraphicsImageRenderer(size: size)
        return render.image { _ in
            self.draw(in: CGRect(origin: .zero, size: CGSize(width: self.size.width, height: self.size.height)))
            slaveImage.draw(in: CGRect(origin: CGPoint(x: 0, y: self.size.height), size: CGSize(width: self.size.width, height: slaveImage.size.height)))
        }
    }
}

public extension UIImage{
    /**
     加载本地大图
     
     - parameter name 图片名
     */
    class func largerImage(name: String) -> UIImage? {
        return self.largerImage(name: name, type: "png")
    }
    
    /**
     加载本地大图
     
     - parameter name 图片名
     - parameter type 图片类型
     
     - returns 大图
     */
    class func largerImage(name: String, type: String) -> UIImage? {
        guard let path = Bundle.main.path(forResource: name, ofType: type) else {
            return nil
        }
        
        return UIImage.init(contentsOfFile: path)
    }
}

public extension UIImage{
    /**
     图片压缩
     - parameter maxLength 图片大小 默认10M
     - returns 压缩后的图片
     */
    func compressImage(maxLength: Int = 10 * 1024 * 1024) -> UIImage {
        let tempMaxLength: Int = maxLength / 8
        var compression: CGFloat = 1
        guard var data = self.jpegData(compressionQuality: compression), data.count > tempMaxLength else {
            return self
        }
        // 压缩大小
        var max: CGFloat = 1
        var min: CGFloat = 0
        for _  in 0..<6 {
            compression = (max + min) / 2
            guard let compressedData = self.jpegData(compressionQuality: compression) else { break }
            data = compressedData
            if CGFloat(data.count) < CGFloat(tempMaxLength) * 0.9 {
                min = compression
            } else if data.count > tempMaxLength {
                max = compression
            } else {
                break
            }
        }
        var resultImage: UIImage = UIImage(data: data) ?? self
        if data.count < tempMaxLength {
            return resultImage
        }
        // 压缩大小
        var lastDataLength: Int = 0
        while data.count > tempMaxLength && data.count != lastDataLength {
            lastDataLength = data.count
            let ratio: CGFloat = CGFloat(tempMaxLength) / CGFloat(data.count)
            let size: CGSize = CGSize(width: Int(resultImage.size.width * sqrt(ratio)),
                                      height: Int(resultImage.size.height * sqrt(ratio)))
            UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
            resultImage.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
            guard let resizedImage = UIGraphicsGetImageFromCurrentImageContext() else {
                UIGraphicsEndImageContext()
                break
            }
            resultImage = resizedImage
            UIGraphicsEndImageContext()
            guard let compressedData = resultImage.jpegData(compressionQuality: compression) else { break }
            data = compressedData
        }
        return resultImage
    }
    
    /**
     图片压缩
     - parameter maxLength 图片大小 默认10M
     - returns 压缩后的数据
     */
    func compressData(maxLength: Int = 10 * 1024 * 1024) -> Data {
        var compression: CGFloat = 1
        guard var data = self.jpegData(compressionQuality: compression), data.count > maxLength else {
            return self.jpegData(compressionQuality: compression) ?? Data()
        }
        // 压缩大小
        var max: CGFloat = 1
        var min: CGFloat = 0
        for _  in 0..<6 {
            compression = (max + min) / 2
            guard let compressedData = self.jpegData(compressionQuality: compression) else { break }
            data = compressedData
            if CGFloat(data.count) < CGFloat(maxLength) * 0.9 {
                min = compression
            } else if data.count > maxLength {
                max = compression
            } else {
                break
            }
        }
        var resultImage: UIImage = UIImage(data: data) ?? self
        if data.count < maxLength {
            return data
        }
        // 压缩大小
        var lastDataLength: Int = 0
        while data.count > maxLength && data.count != lastDataLength {
            lastDataLength = data.count
            let ratio: CGFloat = CGFloat(maxLength) / CGFloat(data.count)
            let size: CGSize = CGSize(width: Int(resultImage.size.width * sqrt(ratio)),
                                      height: Int(resultImage.size.height * sqrt(ratio)))
            UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
            resultImage.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
            guard let resizedImage = UIGraphicsGetImageFromCurrentImageContext() else {
                UIGraphicsEndImageContext()
                break
            }
            resultImage = resizedImage
            UIGraphicsEndImageContext()
            guard let compressedData = resultImage.jpegData(compressionQuality: compression) else { break }
            data = compressedData
        }
        return data
    }
}
