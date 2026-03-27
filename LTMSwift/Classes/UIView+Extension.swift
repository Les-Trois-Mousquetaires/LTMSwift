//
//  UIView+Extension.swift
//  LTMSwift
//
//  Created by 柯南 on 2022/11/29.
//

import Foundation

private let ltmDashLineLayerName = "com.ltmswift.dash.line"
private let ltmGradientLayerName = "com.ltmswift.gradient.layer"

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
        layer.sublayers?.removeAll(where: { $0.name == ltmGradientLayerName })

        let gradientLocations:[NSNumber] = [0, 1]
        let gradientLayer = CAGradientLayer()
        gradientLayer.name = ltmGradientLayerName
        gradientLayer.colors = colors
        gradientLayer.locations = gradientLocations
        
        gradientLayer.startPoint = startPoint ?? CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = endPoint ?? CGPoint(x: 1, y: 0)
        gradientLayer.frame = bounds
        layer.insertSublayer(gradientLayer, at: 0)
    }
}

public extension UIView{
    /// View生成图片
    var viewImage: UIImage {
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, true, UIScreen.main.scale)
        guard let context = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndImageContext()
            return UIImage()
        }
        self.layer.render(in: context)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image ?? UIImage()
    }
    
    /// View生成图片,可以显示layer(分享分时图、k线)
    var layerImage: UIImage {
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, true, 0.0)
        self.drawHierarchy(in: self.bounds, afterScreenUpdates: true)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image ?? UIImage()
    }
        
    /// 将 scrollView 生成长图，非 scrollView 则返回当前 view 截图。
    var scrollViewImage: UIImage {
        guard let scrollView = self as? UIScrollView else {
            return viewImage
        }
        return scrollView.captureLongImage ?? UIImage()
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
        self.layer.sublayers?.removeAll(where: { $0.name == ltmDashLineLayerName })
        let shapeLayer = CAShapeLayer()
        shapeLayer.name = ltmDashLineLayerName
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
