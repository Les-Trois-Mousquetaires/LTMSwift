//
//  LTMExtensionView.swift
//  ZhiHuiKuangShan
//
//  Created by 柯南 on 2020/7/6.
//  Copyright © 2020 TianRui. All rights reserved.
//

import UIKit

extension UIView{
    /**
     添加多个子视图
     */
    func addSubViews(_ views: [UIView]) {
        views.forEach({
            addSubview($0)
        })
    }
    
    /**
     设置视图圆角
     
     - parameter view 视图
     - parameter radius 圆角大小
     - parameter roundingCorners 圆角方位
     */
    func setCornersRadius(_ view: UIView!, radius: CGFloat, roundingCorners: UIRectCorner) {
        if view == nil {
            return
        }
        let maskPath = UIBezierPath(roundedRect: view.bounds, byRoundingCorners: roundingCorners, cornerRadii: CGSize(width: radius, height: radius))
        let maskLayer = CAShapeLayer()
        maskLayer.frame = view.bounds
        maskLayer.path = maskPath.cgPath
        maskLayer.shouldRasterize = true
        maskLayer.rasterizationScale = UIScreen.main.scale
        
        view.layer.mask = maskLayer
    }
    
    /**
     设置渐变色
     
     - parameter startPoint 渐变起始点 默认0.0
     - parameter endPoint 渐变结束点 默认1.0
     - parameter colors 渐变颜色数组
    */
    func setGradient(startPoint: CGPoint?, endPoint: CGPoint?, colors:[Any]){
        let gradientLocations:[NSNumber] = [0, 1]
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = colors
        gradientLayer.locations = gradientLocations
        
        gradientLayer.startPoint = startPoint ?? CGPoint.init(x: 0, y: 0)
        gradientLayer.endPoint = endPoint ?? CGPoint.init(x: 1, y: 0)
        gradientLayer.frame = self.bounds
        self.layer.insertSublayer(gradientLayer, at: 0)
        
        //return gradientLayer
    }
}

extension UIView{
    /**
     View生成图片
     */
    func makeImage() -> UIImage{
        //第一个参数表示区域大小。第二个参数表示是否是非透明的，如果需要显示半透明效果，需要传NO，否则传YES。第三个参数就是屏幕密度了
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, true, UIScreen.main.scale)
        self.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image!
    }
    
    /**
     View生成图片,可以显示layer(分享分时图、k线)
     */
    func makeLayerImage() -> UIImage{
        //第一个参数表示区域大小。第二个参数表示是否是非透明的，如果需要显示半透明效果，需要传NO，否则传YES。第三个参数就是屏幕密度了
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, true, 0.0)
        self.drawHierarchy(in: self.bounds, afterScreenUpdates: true)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image!
    }
    
    /**
     将tableview 生成图片
     */
    func getTableViewImage() -> UIImage{
        var image = UIImage()
        let scrollView: UIScrollView = self as! UITableView
        //第一个参数表示区域大小。第二个参数表示是否是非透明的，如果需要显示半透明效果，需要传NO，否则传YES。第三个参数就是屏幕密度了
        UIGraphicsBeginImageContextWithOptions(CGSize(width: scrollView.contentSize.width, height: scrollView.contentSize.height), false, 0.0)
        let savedContentOffset: CGPoint = scrollView.contentOffset
        let savedFrame: CGRect = scrollView.frame
        scrollView.contentOffset = CGPoint.zero
        scrollView.frame = CGRect(origin: CGPoint(x: 0,y :0), size: CGSize(width: scrollView.contentSize.width, height: scrollView.contentSize.height))
        scrollView.layer.render(in: UIGraphicsGetCurrentContext()!)
        image = UIGraphicsGetImageFromCurrentImageContext()!
        scrollView.contentOffset = savedContentOffset
        scrollView.frame = savedFrame
        UIGraphicsEndImageContext()
        
        return image
    }
}
