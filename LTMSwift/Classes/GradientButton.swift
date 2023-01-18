//
//  GradientButton.swift
//  Alamofire
//
//  Created by 柯南 on 2023/1/18.
// 渐变按钮

import Foundation

open class GradientButton: UIButton {
    /// 是否渐变
    @IBInspectable public var isGradient: Bool = true
    /// 渐变起始颜色
    @IBInspectable public var startColor: UIColor = .white
    /// 渐变结束颜色
    @IBInspectable public var endColor: UIColor = .white
    /// 渐变位置
    @IBInspectable public var locations: [NSNumber] = [0 , 1]
    /// 渐变起始点
    @IBInspectable public var startPoint: CGPoint = CGPointMake(0, 0)
    /// 渐变结束点
    @IBInspectable public var endPoint: CGPoint = CGPointMake(1, 1)
    
    private var gradientBGLayer: CAGradientLayer?
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        gradientBGLayer?.removeFromSuperlayer()
        if isGradient {
            gradientBGLayer = CAGradientLayer()
            gradientBGLayer!.colors = [startColor.cgColor, endColor.cgColor]
            gradientBGLayer!.locations = locations
            gradientBGLayer!.frame = bounds
            gradientBGLayer!.startPoint = startPoint
            gradientBGLayer!.endPoint = endPoint
            self.layer.insertSublayer(gradientBGLayer!, at: 0)
        }
    }
}
