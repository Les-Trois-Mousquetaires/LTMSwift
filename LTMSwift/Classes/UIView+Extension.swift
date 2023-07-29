//
//  UIView+Extension.swift
//  LTMSwift
//
//  Created by 柯南 on 2022/11/29.
//

import Foundation

public extension UIView{
    /**
     添加多个子视图
     */
    func addSubViews(_ views: [UIView]) {
        views.forEach({
            addSubview($0)
        })
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
    }
}

public extension UIView{
    /// View生成图片
    var image: UIImage {
        //第一个参数表示区域大小。第二个参数表示是否是非透明的，如果需要显示半透明效果，需要传NO，否则传YES。第三个参数就是屏幕密度了
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, true, UIScreen.main.scale)
        self.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image!
    }
    
    /// View生成图片,可以显示layer(分享分时图、k线)
    var layerImage: UIImage {
        //第一个参数表示区域大小。第二个参数表示是否是非透明的，如果需要显示半透明效果，需要传NO，否则传YES。第三个参数就是屏幕密度了
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, true, 0.0)
        self.drawHierarchy(in: self.bounds, afterScreenUpdates: true)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image!
    }
        
    /// 将scrollView 生成图片
    var scrollViewImage: UIImage {
        var image = UIImage()
        let scrollView: UIScrollView = self as! UIScrollView
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

public extension UIView {
    /**
     绘制虚线
     
     - parameter lineColor 虚线颜色
     - parameter isHorizonal 虚线是否横向
     - parameter lineWidth 每段虚线宽
     - parameter lineLength 每段虚线长
     - parameter lineSpacing 虚线间距
     */
    func drawDashLine(lineColor: UIColor, isHorizonal: Bool = true, lineWidth: CGFloat = 1, lineLength: Int = 5, lineSpacing: Int = 5) {
        self.layoutIfNeeded()
        let shapeLayer = CAShapeLayer()
        shapeLayer.bounds = self.bounds
        shapeLayer.position = CGPoint(x: self.frame.width / 2, y: self.frame.height / 2)
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = lineColor.cgColor
        shapeLayer.lineWidth = lineWidth
        shapeLayer.lineJoin = CAShapeLayerLineJoin.round
        shapeLayer.lineDashPhase = 0 //从哪个位置开始
        //每一段虚线长度 和 每两段虚线之间的间隔
        shapeLayer.lineDashPattern = [NSNumber(value: lineLength), NSNumber(value: lineSpacing)]
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: 0))
        if (isHorizonal){
            path.addLine(to: CGPoint(x: self.layer.bounds.width, y: 0))
        }else{
            path.addLine(to: CGPoint(x: 0, y: self.layer.bounds.height))
        }
        shapeLayer.path = path
        self.layer.addSublayer(shapeLayer)
    }
}
