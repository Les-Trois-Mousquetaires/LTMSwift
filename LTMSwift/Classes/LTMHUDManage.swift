//
//  LTMHUDManage.swift
//  LTMSwift
//
//  Created by 柯南 on 2022/11/29.
//

/*
 HUD显示时默认是屏蔽事件的
 如果想取消在调用的时候统一设置(LTMHUDManage.isReceiveEvent = true)即可
 */
import Foundation
import UIKit

private let hudreserved: CGFloat = 15 // 预留空间
private let hudmaxWidth: CGFloat = (UIScreen.main.bounds.size.width - 100) // 文字最大宽度
private let hudiconWH: CGFloat = 36 // 图片大小
private let hudlabelSize: CGFloat = 14 // 文本大小
private let hudlineSpacing: CGFloat = 3 // 行间距
 
open class LTMHUDManage: NSObject {
    // MARK: - HUD相关
    static let instance: LTMHUDManage = LTMHUDManage()
    /// 是否接收事件 默认不接收 如果显示是想屏蔽事件需要把 isReceiveEvent = true
    static var isReceiveEvent = false
    class var shared: LTMHUDManage {
        return instance
    }
    
    /// 加载HUD
    /// - Parameter name: 提示语
   public func ltm_showLoading(_ name: String = "正在加载",_ time: TimeInterval? = nil) {
        if time == nil {
            LTMProgressHUD.show(.loading, name, 60)
        } else {
            LTMProgressHUD.show(.loading, name, time ?? 1)
        }
    }
    
    /**
     只显示文字
     
     - parameter name 提示语
     - parameter delay 延迟时间
     */
    public func ltm_showtitle(_ name: String?,_ delay: TimeInterval = 1) {
        LTMProgressHUD.show(.none, name ?? "", delay)
    }
    
    /**
     显示警告
     
     - parameter name 提示语
     - parameter delay 延迟时间
     */
    public func ltm_showInfo(_ name: String?,_ delay: TimeInterval = 1) {
        LTMProgressHUD.show(.info, name ?? "", delay)
    }
    
    /// 隐藏HUD
    public func ltm_dismiss() {
        LTMProgressHUD.dismiss()
    }
    
    /// 成功提示
    public func ltm_showSuccess(_ name: String) {
        LTMProgressHUD.show(.success, name, 1)
    }
    
    /// 失败提示
    public func ltm_showError(_ name: String) {
        LTMProgressHUD.show(.error, name, 1)
    }
}

public extension UIViewController {
    /// HUD管理者 使用 HUDManage.ltm_showtitleHUD("HUD")
    @IBInspectable var HUDManage: LTMHUDManage! {
        get {
            return LTMHUDManage.shared
        }
        set {}
    }
}

public extension UIView {
    /// HUD管理者 使用 HUDManage.ltm_showtitleHUD("HUD")
    @IBInspectable var HUDManage: LTMHUDManage! {
        get {
            return LTMHUDManage.shared
        }
        set {}
    }
}

public typealias HUDCompletedBlock = () -> Void

public enum LTMProgressHUDType {
    case loading // 加载
    case success // 成功
    case error   // 失败
    case info    // 警告
    case none    // 文字
}

public extension LTMProgressHUD {
    
    /**
     显示hud
     
     - parameter type 类型
     - parameter text 内容
     - parameter time 消失时间
     - parameter completion 消失时回调
     */
    class func show(_ type: LTMProgressHUDType,_ text: String,_ time: TimeInterval = 1, completion: HUDCompletedBlock? = nil) {
        dismiss()
        instance.registerDeviceOrientationNotification()
        var isNone: Bool = false
        let window = UIWindow()
        window.backgroundColor = UIColor.clear
        let mainView = UIView()
        mainView.layer.cornerRadius = 10
        mainView.backgroundColor = UIColor(red:0, green:0, blue:0, alpha: 0.7)
        
        var image = UIImage()
        var headView = UIView()
        switch type { /// 添加图片
        case .success:
            image = imageOfCheckmark
        case .error:
            image = imageOfCross
        case .info:
            image = imageOfInfo
        default:
            break
        }
        
        switch type { // 添加 headView
        case .loading:
            headView = UIActivityIndicatorView(style: .whiteLarge)
            (headView as! UIActivityIndicatorView).startAnimating()
            headView.translatesAutoresizingMaskIntoConstraints = false
            mainView.addSubview(headView)
        case .success: // 加了fallthrough后，会直接运行【紧跟的后一个】
            fallthrough
        case .error:
            fallthrough
        case .info:
            headView = UIImageView(image: image)
            headView.translatesAutoresizingMaskIntoConstraints = false
            mainView.addSubview(headView)
        case .none:
            isNone = true
        }
        
        // label
        let label = UILabel()
        label.text = text
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: hudlabelSize)
        label.textColor = UIColor.white
        label.translatesAutoresizingMaskIntoConstraints = false
        let arr = NSMutableAttributedString(string: text).hud_addLineSpacing(hudlineSpacing)
        label.attributedText = arr
        
        var height: CGFloat = text.count > 0 ? arr.hud_getHeight(hudmaxWidth) : 0 // 因为加了行间距 高度不可能=0 (所有用是否有内容来判断)
        height = height+height/label.font.pointSize*hudlineSpacing
        var width = arr.hud_getWidth(CGFloat(MAXFLOAT), hudmaxWidth)
        if !isNone { // 有图标
            width = height > 0 ? width : hudiconWH
            height = height > 0 ? height+hudiconWH+hudreserved : hudiconWH
        }
        label.textAlignment = NSTextAlignment.center
        mainView.addSubview(label)
        
        if LTMHUDManage.isReceiveEvent == false { // 不接受事件
            window.frame = UIScreen.main.bounds
            mainView.frame = CGRect(x: (UIScreen.main.bounds.size.width-(width+hudreserved*4))/2, y: (UIScreen.main.bounds.size.height-(height+hudreserved*2))/2, width: width+hudreserved*4, height: height+hudreserved*2)
        } else {
            let superFrame = CGRect(x: 0, y: 0, width: width+hudreserved*4, height: height+hudreserved*2)
            window.frame = superFrame
            mainView.frame = superFrame
        }
        
        // image
        if !isNone { // 有图标
            mainView.addConstraint(NSLayoutConstraint(item: headView, attribute: NSLayoutConstraint.Attribute.top, relatedBy: NSLayoutConstraint.Relation.lessThanOrEqual, toItem: mainView, attribute: NSLayoutConstraint.Attribute.top, multiplier: 1, constant: hudreserved))
            mainView.addConstraint(NSLayoutConstraint(item: headView, attribute: .centerX, relatedBy: .equal, toItem: mainView, attribute: .centerX, multiplier: 1.0, constant: 0) )
            mainView.addConstraint(NSLayoutConstraint(item: headView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: hudiconWH))
            mainView.addConstraint(NSLayoutConstraint(item: headView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: hudiconWH))
        }
        // label
        if !isNone { // 如果有图标 + 图标高度 图标和文字间距15
            let labelTop = hudreserved + hudiconWH + hudreserved
            mainView.addConstraint(NSLayoutConstraint(item: label, attribute: NSLayoutConstraint.Attribute.top, relatedBy: NSLayoutConstraint.Relation.lessThanOrEqual, toItem: mainView, attribute: NSLayoutConstraint.Attribute.top, multiplier: 1, constant: labelTop))
        } else { // 没有图标 直接居中
            mainView.addConstraint(NSLayoutConstraint(item: label, attribute: NSLayoutConstraint.Attribute.centerY, relatedBy: NSLayoutConstraint.Relation.lessThanOrEqual, toItem: mainView, attribute: NSLayoutConstraint.Attribute.centerY, multiplier: 1, constant: 0))
        }
        mainView.addConstraint( NSLayoutConstraint(item: label, attribute: .centerX, relatedBy: .equal, toItem: mainView, attribute: .centerX, multiplier: 1.0, constant: 0) )
        mainView.addConstraint( NSLayoutConstraint(item: label, attribute: .width, relatedBy: .lessThanOrEqual, toItem: nil, attribute: .width, multiplier: 1.0, constant: hudmaxWidth))
        mainView.addConstraint( NSLayoutConstraint(item: label, attribute: .height, relatedBy: .greaterThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 0) )
        window.windowLevel = UIWindow.Level.alert
        window.center = getCenter()
        window.isHidden = false
        window.addSubview(mainView)
        windowsTemp.append(window)
        if time != 0 {
            delayDismiss(time, completion: completion)
        }
    }
    
    class func dismiss() {
        timer?.cancel()
        timer = nil
        instance.removeDeviceOrientationNotification()
        if let currentwindow = windowsTemp.last {
            for view in currentwindow.subviews {
                view.removeFromSuperview()
            }
        }
        windowsTemp.removeAll(keepingCapacity: false)
    }
}

open class LTMProgressHUD: NSObject {
    fileprivate static var windowsTemp = [UIWindow]()
    fileprivate static var timer: DispatchSourceTimer?
    fileprivate static let instance = LTMProgressHUD()
    private struct Cache {
        static var imageOfCheckmark: UIImage?
        static var imageOfCross: UIImage?
        static var imageOfInfo: UIImage?
    }
    
    // center
    fileprivate class func getCenter() -> CGPoint {
        return CGPoint(x: UIScreen.main.bounds.width/2, y: UIScreen.main.bounds.height/2)
    }
    
    // delay dismiss
    fileprivate class func delayDismiss(_ time: TimeInterval?, completion: HUDCompletedBlock?) {
        guard let time = time else { return }
        guard time > 0 else { return }
        var timeout = time
        timer = DispatchSource.makeTimerSource(flags: DispatchSource.TimerFlags(rawValue: 0),
                                               queue: DispatchQueue.main)// as! DispatchSource
        timer!.schedule(wallDeadline: .now(), repeating: .seconds(1))
        timer!.setEventHandler {
            if timeout <= 0 {
                DispatchQueue.main.async {
                    dismiss()
                    completion?()
                }
            } else {
                timeout -= 1
            }
        }
        timer!.resume()
    }
    
    // register notification
    fileprivate func registerDeviceOrientationNotification() {
        NotificationCenter.default.addObserver(LTMProgressHUD.instance, selector: #selector(LTMProgressHUD.transformWindow(_:)), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    // remove notification
    fileprivate func removeDeviceOrientationNotification() {
        NotificationCenter.default.removeObserver(LTMProgressHUD.instance)
    }
    
    // transform
    @objc fileprivate func transformWindow(_ notification: Notification) {
        var rotation: CGFloat = 0
        switch UIDevice.current.orientation {
        case .portrait:
            rotation = 0
        case .portraitUpsideDown:
            rotation = .pi
        case .landscapeLeft:
            rotation = .pi * 0.5
        case .landscapeRight:
            rotation = CGFloat(.pi + (.pi * 0.5))
        default:
            break
        }
        LTMProgressHUD.windowsTemp.forEach {
            $0.center = LTMProgressHUD.getCenter()
            $0.transform = CGAffineTransform(rotationAngle: rotation)
        }
    }
    
    // draw
    // MARK: - 绘画
    private class func draw(_ type: LTMProgressHUDType) {
        let checkmarkShapePath = UIBezierPath()
        switch type {
        case .success: // draw checkmark
            checkmarkShapePath.move(to: CGPoint(x: 5, y: 21))
            checkmarkShapePath.addLine(to: CGPoint(x: 16, y: 32))
            checkmarkShapePath.addLine(to: CGPoint(x: 35, y:11))
            checkmarkShapePath.move(to: CGPoint(x: 5, y: 21))
            checkmarkShapePath.close()
        case .error: // draw X
            checkmarkShapePath.move(to: CGPoint(x: 7, y: 10))
            checkmarkShapePath.addLine(to: CGPoint(x: 29, y: 31))
            checkmarkShapePath.move(to: CGPoint(x: 7, y: 31))
            checkmarkShapePath.addLine(to: CGPoint(x: 29, y: 10))
            checkmarkShapePath.move(to: CGPoint(x: 7, y: 10))
            checkmarkShapePath.close()
        case .info:
            checkmarkShapePath.move(to: CGPoint(x: 18, y: 10))
            checkmarkShapePath.addLine(to: CGPoint(x: 18, y: 26))
            checkmarkShapePath.move(to: CGPoint(x: 18, y: 10))
            checkmarkShapePath.close()
            UIColor.white.setStroke()
            checkmarkShapePath.stroke()
            let checkmarkShapePath = UIBezierPath()
            checkmarkShapePath.move(to: CGPoint(x: 18, y: 31))
            checkmarkShapePath.addArc(withCenter: CGPoint(x: 18, y: 31), radius: 1, startAngle: 0, endAngle: .pi * 2, clockwise: true)
            checkmarkShapePath.close()
            UIColor.white.setFill()
            checkmarkShapePath.fill()
        default: break
        }
        UIColor.white.setStroke()
        checkmarkShapePath.stroke()
    }
    // MARK: - 画勾
    fileprivate class var imageOfCheckmark: UIImage {
        if (Cache.imageOfCheckmark != nil) {
            return Cache.imageOfCheckmark!
        }
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 36, height: 36), false, 0)
        LTMProgressHUD.draw(.success)
        Cache.imageOfCheckmark = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return Cache.imageOfCheckmark!
    }
    // MARK: - 画X
    fileprivate class var imageOfCross: UIImage {
        if (Cache.imageOfCross != nil) {
            return Cache.imageOfCross!
        }
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 36, height: 36), false, 0)
        LTMProgressHUD.draw(.error)
        Cache.imageOfCross = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return Cache.imageOfCross!
    }
    // MARK: - 画!
    fileprivate class var imageOfInfo: UIImage {
        if (Cache.imageOfInfo != nil) {
            return Cache.imageOfInfo!
        }
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 36, height: 36), false, 0)
        LTMProgressHUD.draw(.info)
        Cache.imageOfInfo = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return Cache.imageOfInfo!
    }
}

public extension NSMutableAttributedString {
    /// 获取范围
    func hud_allRange() -> NSRange {
        return NSMakeRange(0,length)
    }
    /// 添加行间距
    @discardableResult
    func hud_addLineSpacing(_ lineSpacing:CGFloat) -> NSMutableAttributedString {
        let paragraphStyle : NSMutableParagraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = lineSpacing //大小调整
        self.addAttribute(NSAttributedString.Key.paragraphStyle, value: paragraphStyle, range: hud_allRange())
        return self
    }
    /// 计算字符串的高度
    @discardableResult
    func hud_getHeight(_ width : CGFloat) -> CGFloat {
        let rect = self.boundingRect(with: CGSize.init(width: width, height: CGFloat(MAXFLOAT)), options: NSStringDrawingOptions.usesLineFragmentOrigin, context: nil)
        return rect.size.height
    }
    /// 计算富文本的宽度
    /// - Parameter height: 最大高度
    /// - Returns: 宽度
    @discardableResult
    func hud_getWidth(_ height: CGFloat, _ with: CGFloat = CGFloat(MAXFLOAT)) -> CGFloat {
        let rect = self.boundingRect(with: CGSize.init(width: with, height: height), options: NSStringDrawingOptions.usesLineFragmentOrigin, context: nil)
        return rect.size.width
    }
}
