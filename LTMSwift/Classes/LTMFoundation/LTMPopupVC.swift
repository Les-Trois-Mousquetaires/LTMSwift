//
//  LTMPopupVC.swift
//  Pods
//
//  Created by 柯南 on 2020/8/3.
//

import Foundation
import UIKit

public enum LTMPopupMaskType: Int {
    case BlackBlur, WhiteBlur, White, Clear, BlackTranslucent
}

// default Center
public enum LTMPopupLayoutType: Int {
    case Top, Bottom, Left, Right, Center
}

// default Fade
public enum LTMPopupSlideStyle: Int {
    case Top, Bottom, Left, Right, ShrinkInOut1, ShrinkInOut2, Fade
}

open class LTMPopupVC: NSObject, UIGestureRecognizerDelegate{
    /// Set popup view display position. default is .Center
    public var layoutType: LTMPopupLayoutType = .Center
    /// Set popup view slide Style. default is .Fade, layoutType = .Center is vaild
    public var slideStyle: LTMPopupSlideStyle = .Fade
    // default true
    public  var dismissOnMaskTouched: Bool = true
    // default false, layoutType = .Center is vaild
    public var dismissOppositeDirection: Bool = false
    // default 0
    public var offsetSpacingOfKeyboard: CGFloat = 0.0
    
    public var maskTouched: ((LTMPopupVC) -> Void)?
    public var willPresent: ((LTMPopupVC) -> Void)?
    public var didPresent: ((LTMPopupVC) -> Void)?
    public var willDismiss: ((LTMPopupVC) -> Void)?
    public  var didDismiss: ((LTMPopupVC) -> Void)?
    
    private var popupView: UIView!
    private var superView: UIView!
    private var maskView: UIView!
    private var contentView: UIView!
    
    private var maskAlpha: CGFloat = 0.6
    private var isPresenting: Bool = false
    // default false
    private var allowPan: Bool = false
    private var dropAngle: CGFloat = 0
    // last keyboard finished center
    private var markerCenter: CGPoint = CGPoint.zero
    private var maskType: LTMPopupMaskType = .BlackTranslucent
    private var timer: Timer!
    private var duration: TimeInterval?
    private var isSpringAnimated: Bool = false
    
    override init() {
        super.init()
        setupSubviews(maskType: .BlackTranslucent)
    }
    
    init(maskType: LTMPopupMaskType) {
        super.init()
        setupSubviews(maskType: maskType)
    }
    
    private func setupSubviews(maskType: LTMPopupMaskType) {
        // superview
        superView = frontWindow()
        
        // maskview
        if maskType == .BlackBlur || maskType == .WhiteBlur {
            if UIDevice.current.systemVersion.compare("8.0") == ComparisonResult.orderedAscending {
                maskView = UIToolbar(frame: superView.bounds)
            } else {
                maskView = UIView(frame: superView.bounds)
                let visualEffectView = UIVisualEffectView()
                visualEffectView.effect = UIBlurEffect(style: UIBlurEffect.Style.light)
                visualEffectView.frame = superView.bounds
                maskView.insertSubview(visualEffectView, at: 0)
            }
        } else {
            maskView = UIView(frame: superView.bounds)
        }
        
        switch maskType {
        case .BlackBlur:
            if maskView.isKind(of: UIToolbar.self) {
                (maskView as! UIToolbar).barStyle = UIBarStyle.black
            } else {
                let effectView = maskView.subviews.first as! UIVisualEffectView
                effectView.effect = UIBlurEffect(style: UIBlurEffect.Style.dark)
            }
            break
        case .WhiteBlur:
            if maskView.isKind(of: UIToolbar.self) {
                (maskView as! UIToolbar).barStyle = UIBarStyle.default
            } else {
                let effectView = maskView.subviews.first as! UIVisualEffectView
                effectView.effect = UIBlurEffect(style: UIBlurEffect.Style.light)
            }
            break
        case .White:
            maskView.backgroundColor = UIColor.white
            break
        case .Clear:
            maskView.backgroundColor = UIColor.clear
            break
        case .BlackTranslucent:
            maskView.backgroundColor = UIColor(white: 0.0, alpha: maskAlpha)
            break
        }
        
        let tap = UITapGestureRecognizer(target: self, action:#selector(handleTap))
        tap.delegate = self
        maskView.addGestureRecognizer(tap)
        
        popupView = UIView()
        popupView.backgroundColor = UIColor.clear
        
        maskView.addSubview(popupView)
        superView.addSubview(maskView)
        
        // Observer statusBar orientation changes.
        bindNotificationEvent()
    }
    
    // MARK: - Observing
    
    private func bindNotificationEvent() {
        unbindNotificationEvent()
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        NotificationCenter.default.addObserver(self, selector: #selector(willChangeStatusBarOrientation), name: UIApplication.willChangeStatusBarOrientationNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didChangeStatusBarOrientation), name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)
        //        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    
    private func unbindNotificationEvent() {
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
        NotificationCenter.default.removeObserver(self, name: UIApplication.willChangeStatusBarOrientationNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)
        //        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    
    @objc private func keyboardWillChangeFrame(_ notification: Notification) {
        // The pan gesture will be invaild when the keyboard appears
        allowPan = false
        guard let userInfo = notification.userInfo else {
            return
        }
        var keyboardRect = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as! CGRect
        keyboardRect = maskView.convert(keyboardRect, from: nil)
        let keyboardHeight = maskView.bounds.height - keyboardRect.minY
        
        let curve = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as! Int
        let options = curve << 16
        
        let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as! Double
        
        UIView.animate(withDuration: duration, delay: 0, options: UIView.AnimationOptions(rawValue: UIView.AnimationOptions.RawValue(options)), animations: {
            if keyboardHeight > 0 {
                var offsetSpacing = self.offsetSpacingOfKeyboard, changeHeight:CGFloat = 0
                
                switch self.layoutType {
                case .Top:
                    break
                case .Bottom:
                    changeHeight = keyboardHeight + offsetSpacing
                    break
                default:
                    changeHeight = keyboardHeight / 2 + offsetSpacing
                    break
                }
                
                if !__CGPointEqualToPoint(CGPoint.zero, self.markerCenter) {
                    self.popupView.center = CGPoint(x: self.markerCenter.x, y: self.markerCenter.y - changeHeight)
                } else {
                    self.popupView.center = CGPoint(x: self.popupView.center.x, y: self.popupView.center.y - changeHeight)
                }
            } else {
                if self.isPresenting {
                    self.popupView.center = self.finishedCenter()
                }
            }
        }) { (finished) in
            self.markerCenter = self.finishedCenter()
        }
    }
    
    @objc private func willChangeStatusBarOrientation() {
        maskView.frame = superView.bounds
        popupView.center = finishedCenter()
        innerDismiss()
    }
    
    @objc private func didChangeStatusBarOrientation() {
        if UIDevice.current.systemVersion.compare("8.0") == ComparisonResult.orderedAscending {
            var angle: Double!
            switch UIApplication.shared.statusBarOrientation {
            case .portraitUpsideDown:
                angle = Double.pi
                break
            case .landscapeLeft:
                angle = -Double.pi / 2
                break
            case .landscapeRight:
                angle = Double.pi / 2
                break
            default: // as UIInterfaceOrientationPortrait
                angle = 0.0
                break
            }
            popupView.transform = CGAffineTransform(rotationAngle: CGFloat(angle))
        }
        maskView.frame = superView.bounds
        popupView.center = finishedCenter()
    }
    
    // MARK: - Center point
    
    private func prepareCenterFrom(type: Int, viewRef: UIView) -> CGPoint {
        switch type {
        case 0: //top
            return CGPoint(x: viewRef.center.x, y: -popupView.bounds.height / 2)
        case 1: // bottom
            return CGPoint(x: viewRef.center.x, y: maskView.bounds.height + popupView.bounds.height / 2)
        case 2: // left
            return CGPoint(x: -popupView.bounds.width / 2, y: viewRef.center.y)
        case 3: // right
            return CGPoint(x: maskView.bounds.width + popupView.bounds.width / 2, y: viewRef.center.y)
        default:// center
            return maskView.center
        }
    }
    
    private func prepareCenter() -> CGPoint {
        if layoutType == .Center {
            var point = maskView.center
            if slideStyle == .ShrinkInOut1 {
                popupView.transform = CGAffineTransform(scaleX: 0.15, y: 0.15)
            } else if slideStyle == .ShrinkInOut2 {
                popupView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            } else if slideStyle == .Fade {
                maskView.alpha = 0
            } else {
                point = prepareCenterFrom(type: slideStyle.rawValue, viewRef: maskView)
            }
            return point
        }
        return prepareCenterFrom(type: layoutType.rawValue, viewRef: maskView)
    }
    
    private func finishedCenter() -> CGPoint {
        let point = maskView.center
        
        switch layoutType {
        case .Top:
            return CGPoint(x: point.x, y: popupView.bounds.height / 2)
        case .Bottom:
            return CGPoint(x: point.x, y: maskView.bounds.height - popupView.bounds.height / 2)
        case .Left:
            return CGPoint(x: popupView.bounds.width / 2, y: point.y)
        case .Right:
            return CGPoint(x: maskView.bounds.width - popupView.bounds.width / 2, y: point.y)
        default:
            if slideStyle == .ShrinkInOut1 || slideStyle == .ShrinkInOut2 {
                popupView.transform = CGAffineTransform.identity
            } else if (slideStyle == .Fade) {
                maskView.alpha = 1
            }
        }
        return point
    }
    
    private func dismissedCenter() -> CGPoint {
        if layoutType != .Center {
            return prepareCenterFrom(type: layoutType.rawValue, viewRef: popupView)
        }
        
        switch slideStyle {
        case .Top:
            return dismissOppositeDirection ?
                CGPoint(x: popupView.center.x, y: maskView.bounds.height + popupView.bounds.height / 2) :
                CGPoint(x: popupView.center.x, y: -popupView.bounds.height / 2)
        case .Bottom:
            return dismissOppositeDirection ?
                CGPoint(x: popupView.center.x, y: -popupView.bounds.height / 2):
                CGPoint(x: popupView.center.x, y: maskView.bounds.height + popupView.bounds.height / 2)
        case .Left:
            return dismissOppositeDirection ?
                CGPoint(x: maskView.bounds.width + popupView.bounds.width / 2, y: popupView.center.y):
                CGPoint(x: -popupView.bounds.width / 2, y: popupView.center.y)
        case .Right:
            return dismissOppositeDirection ?
                CGPoint(x: -popupView.bounds.width / 2, y: popupView.center.y):
                CGPoint(x: maskView.bounds.width + popupView.bounds.width / 2, y: popupView.center.y)
        case .ShrinkInOut1:
            popupView.transform = dismissOppositeDirection ?
                CGAffineTransform(scaleX: 1.75, y: 1.75):
                CGAffineTransform(scaleX: 0.25, y: 0.25)
        case .ShrinkInOut2:
            popupView.transform = dismissOppositeDirection ?
                CGAffineTransform(scaleX: 1.2, y: 1.2):
                CGAffineTransform(scaleX: 0.75, y: 0.75)
        case .Fade:
            maskView.alpha = 0
        }
        return popupView.center
    }
    
    // MARK: - Buffer point
    
    private func bufferCenter(move: CGFloat) -> CGPoint {
        var point = popupView.center
        switch layoutType {
        case .Top:
            point.y += move
            break
        case .Bottom:
            point.y -= move
            break
        case .Left:
            point.x += move
            break
        case .Right:
            point.x -= move
            break
        case .Center:
            switch slideStyle {
            case .Top:
                point.y += dismissOppositeDirection ? -move : move
                break
            case .Bottom:
                point.y += dismissOppositeDirection ? move: -move
                break
            case .Left:
                point.x += dismissOppositeDirection ? -move : move
                break
            case .Right:
                point.x += dismissOppositeDirection ? move : -move
                break
            case .ShrinkInOut1, .ShrinkInOut2:
                popupView.transform = dismissOppositeDirection ?
                    CGAffineTransform(scaleX: 0.95, y: 0.95) :
                    CGAffineTransform(scaleX: 1.05, y: 1.05)
                break
            default: break
            }
        }
        return point
    }
    
    // MARK: -  Destroy timer
    
    private func destroyTimer() {
        if timer != nil {
            timer.invalidate()
        }
    }
    
    // MARK: - Add contentView
    private func addContentView(contentView: UIView?) {
        if contentView == nil {
            if popupView.superview != nil {
                popupView.removeFromSuperview()
            }
            return
        }
        self.contentView = contentView
        if self.contentView != popupView {
            self.contentView.frame = CGRect(origin: CGPoint.zero, size: contentView!.frame.size)
            popupView.frame = self.contentView.frame
            popupView.backgroundColor = self.contentView.backgroundColor
            if self.contentView.layer.cornerRadius != 0 {
                popupView.layer.cornerRadius = self.contentView.layer.cornerRadius
                popupView.clipsToBounds = false
            }
            popupView.addSubview(self.contentView)
        }
    }
    
    private func removeSubviews() {
        if popupView.subviews.count > 0 {
            contentView.removeFromSuperview()
            contentView = nil
        }
        maskView.removeFromSuperview()
    }
    
    
    // MARK: - UIGestureRecognizerDelegate
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if touch.view?.isDescendant(of: popupView) ?? false {
            return false
        }
        return true
    }
    
    @objc private func handleTap() {
        if dismissOnMaskTouched {
            if maskTouched != nil {
                maskTouched!(self)
            } else {
                innerDismiss()
            }
        }
    }
    
    @objc private func handlePan(_ pan:UIPanGestureRecognizer){
        if !allowPan || !isPresenting || dropAngle != 0 {
            return
        }
        
        let translation = pan.translation(in: maskView)
        switch pan.state {
        case .began:
            break
        case .changed:
            switch layoutType {
            case .Center:
                var isTransformationVertical = false
                switch slideStyle {
                case .Left, .Right: break
                default:
                    isTransformationVertical = true
                    break
                }
                // set screen ratio `_maskView.bounds.size.height / factor`
                let factor: CGFloat = 4
                let changeValue: CGFloat!
                if isTransformationVertical {
                    pan.view?.center = CGPoint(x: pan.view!.center.x, y: pan.view!.center.y + translation.y)
                    changeValue = pan.view!.center.y / (maskView.bounds.height / factor)
                } else {
                    pan.view?.center = CGPoint(x: pan.view!.center.x + translation.x, y: pan.view!.center.y)
                    changeValue = pan.view!.center.x / (maskView.bounds.width / factor)
                }
                let alpha = factor / 2 - abs(changeValue - factor / 2)
                UIView.animate(withDuration: 0.15) {
                    self.maskView.alpha = alpha
                }
                break
            case .Bottom:
                if pan.view!.frame.origin.y + translation.y > maskView.bounds.height - pan.view!.bounds.height {
                    pan.view?.center = CGPoint(x: pan.view!.center.x, y: pan.view!.center.y + translation.y)
                }
                break
            case .Top:
                if pan.view!.frame.origin.y + pan.view!.frame.size.height + translation.y  < pan.view!.bounds.size.height {
                    pan.view?.center = CGPoint(x: pan.view!.center.x, y: pan.view!.center.y + translation.y)
                }
                break
            case .Left:
                if pan.view!.frame.origin.x + pan.view!.frame.size.width + translation.x < pan.view!.bounds.size.width {
                    pan.view?.center = CGPoint(x: pan.view!.center.x + translation.x ,y: pan.view!.center.y)
                }
                break
            case .Right:
                if pan.view!.frame.origin.x + translation.x > maskView.bounds.size.width - pan.view!.bounds.size.width {
                    pan.view?.center = CGPoint(x: pan.view!.center.x + translation.x ,y: pan.view!.center.y)
                }
                break
            }
            pan.setTranslation(CGPoint.zero, in: maskView)
            break
        case .ended:
            var isWillDismiss = true, isStyleCentered = false
            switch layoutType {
            case .Center:
                isStyleCentered = true
                if pan.view!.center.y != maskView.center.y {
                    if pan.view!.center.y > maskView.bounds.size.height * 0.25 &&
                        pan.view!.center.y < maskView.bounds.size.height * 0.75 {
                        isWillDismiss = false
                    }
                } else {
                    if pan.view!.center.x > maskView.bounds.size.width * 0.25 &&
                        pan.view!.center.x < maskView.bounds.size.width * 0.75 {
                        isWillDismiss = false
                    }
                }
                break
            case .Bottom:
                isWillDismiss = pan.view!.frame.origin.y > maskView.bounds.size.height - pan.view!.frame.size.height * 0.75
                break
            case .Top:
                isWillDismiss = pan.view!.frame.origin.y + pan.view!.frame.size.height < pan.view!.frame.size.height * 0.75
                break
            case .Left:
                isWillDismiss = pan.view!.frame.origin.x + pan.view!.frame.size.width < pan.view!.frame.size.width * 0.75
                break
            case .Right:
                isWillDismiss = pan.view!.frame.origin.x > maskView.bounds.size.width - pan.view!.frame.size.width * 0.75
                break
            }
            
            if isWillDismiss {
                if isStyleCentered {
                    switch slideStyle {
                    case .ShrinkInOut1, .ShrinkInOut2, .Fade:
                        if pan.view!.center.y < maskView.bounds.height * 0.25 {
                            slideStyle = .Top
                        } else {
                            if pan.view!.center.y > maskView.bounds.height * 0.25 {
                                slideStyle = .Bottom
                            }
                        }
                        dismissOppositeDirection = false
                        break
                    case .Top:
                        dismissOppositeDirection = !(pan.view!.center.y < maskView.bounds.size.height * 0.25)
                        break
                    case .Bottom:
                        dismissOppositeDirection = pan.view!.center.y < maskView.bounds.size.height * 0.25
                        break
                    case .Left:
                        dismissOppositeDirection = !(pan.view!.center.x < maskView.bounds.size.width * 0.25)
                        break
                    case .Right:
                        dismissOppositeDirection = pan.view!.center.x < maskView.bounds.size.width * 0.25
                        break
                    }
                }
                _dismiss(duration: 0.25, isSpringAnimated: false)
            } else {
                // restore view location
                if isSpringAnimated {
                    UIView.animate(withDuration: duration ?? 0.25, delay: 0.0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.2, options: .curveLinear, animations: {
                        pan.view?.center = self.finishedCenter()
                    }, completion: nil)
                } else {
                    UIView.animate(withDuration: duration ?? 0.25, delay: 0.0, options: .curveEaseInOut, animations: {
                        pan.view?.center = self.finishedCenter()
                    }, completion: nil)
                }
            }
            break
        case .cancelled:
            break
        default: break
        }
    }
    
    deinit {
        unbindNotificationEvent()
        removeSubviews()
    }
    
    // MARK: - FrontWindow
    
    private func frontWindow() -> UIView {
        for window in UIApplication.shared.windows {
            let isOnMainScreen = window.screen == UIScreen.main
            let isVisible = !window.isHidden && window.alpha > 0
            if isOnMainScreen && isVisible && window.isKeyWindow {
                return window as UIView
            }
        }
        return UIApplication.shared.delegate!.window!! as UIView
    }
    
    // MARK: - Drop animated
    
    private func dropAnimatedWithRotateAngle(angle: CGFloat) {
        dropAngle = angle
        slideStyle = .Top
    }
    
    private func dropSupport() -> Bool {
        return layoutType == .Center && slideStyle == .Top
    }
    
    private func randomValue(i: CGFloat, j: CGFloat) -> CGFloat {
        if arc4random() % 2 != 0 {
            return i
        }
        return j
    }
    
    private func prepareDropAnimated() {
        if dropAngle != 0 && dropSupport() {
            dismissOppositeDirection = true
            let ty = (maskView.bounds.height + popupView.bounds.height) / 2
            var transform = CATransform3DMakeTranslation(0, -ty, 0)
            transform = CATransform3DRotate(transform, randomValue(i: dropAngle, j: -dropAngle) * CGFloat(Double.pi) / 180, 0, 0, 1.0)
            popupView.layer.transform = transform
        }
    }
    
    private func finishedDropAnimated() {
        if dropAngle != 0 && dropSupport() {
            popupView.layer.transform = CATransform3DIdentity
        }
    }
    
    private func dismissedDropAnimated() {
        if dropAngle != 0 && dropSupport() {
            var transform = CATransform3DMakeTranslation(0, maskView.bounds.height, 0)
            transform = CATransform3DRotate(transform, randomValue(i: dropAngle, j: -dropAngle) * CGFloat(Double.pi) / 180, 0, 0, 1.0)
            popupView.layer.transform = transform
        }
    }
    
    // MARK: - Mask view background
    
    private func prepareBackground() {
        switch maskType {
        case .BlackBlur, .WhiteBlur:
            maskView.alpha = 1
            break
        default:
            maskView.backgroundColor = UIColor(white: 0.0, alpha: 0.0)
        }
    }
    
    private func finishedBackground() {
        switch maskType {
        case .BlackTranslucent:
            maskView.backgroundColor = UIColor(white: 0.0, alpha: maskAlpha)
            break
        case .White:
            maskView.backgroundColor = UIColor.white
            break
        case .Clear:
            maskView.backgroundColor = UIColor.clear
            break
        default:
            break
        }
    }
    
    private func bufferBackground() {
        switch maskType {
        case .BlackBlur, .WhiteBlur:
            break
        case .BlackTranslucent:
            maskView.backgroundColor = UIColor(white: 0.0, alpha: maskAlpha - maskAlpha * 0.15)
            break
        default:
            break
        }
    }
    
    private func dismissedBackground() {
        switch maskType {
        case .BlackBlur, .WhiteBlur:
            maskView.alpha = 0
            break
        default:
            maskView.backgroundColor = UIColor(white: 0.0, alpha: 0)
            break
        }
    }
    
    // MARK: - Present
    
    private func _present(contentView: UIView, duration: TimeInterval, isSpringAnimated: Bool, inView: UIView?, displayTime: TimeInterval) {
        if isPresenting {
            return
        }
        self.duration = duration
        self.isSpringAnimated = isSpringAnimated
        
        if willPresent != nil {
            willPresent!(self)
        }
        
        if inView != nil {
            superView = inView
            maskView.frame = superView.frame
        }
        addContentView(contentView: contentView)
        if !superView.subviews.contains(maskView) {
            superView.addSubview(maskView)
        }
        
        prepareDropAnimated()
        prepareBackground()
        popupView.isUserInteractionEnabled = false
        popupView.center = prepareCenter()
        
        let presentCallback = {
            self.isPresenting = true
            self.popupView.isUserInteractionEnabled = true
            
            if self.didPresent != nil {
                self.didPresent!(self)
            }
            
            if displayTime != 0 {
                self.timer = Timer.scheduledTimer(timeInterval: displayTime, target: self, selector: #selector(self.innerDismiss), userInfo: nil, repeats: false)
                RunLoop.main.add(self.timer, forMode: .common)
            }
        }
        
        if isSpringAnimated {
            UIView.animate(withDuration: duration, delay: 0.0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.2, options: .curveLinear, animations: {
                self.finishedDropAnimated()
                self.finishedBackground()
                self.popupView.center = self.finishedCenter()
            }) { (finished) in
                if finished {
                    presentCallback()
                }
            }
        } else {
            UIView.animate(withDuration: duration, delay: 0.0, options: .curveLinear, animations: {
                self.finishedDropAnimated()
                self.finishedBackground()
                self.popupView.center = self.finishedCenter()
            }) { (finished) in
                if finished {
                    presentCallback()
                }
            }
        }
    }
    
    private func _dismiss(duration: TimeInterval, isSpringAnimated: Bool) {
        destroyTimer()
        
        if !isPresenting {
            return
        }
        
        if willDismiss != nil {
            willDismiss!(self)
        }
        
        let dismissCallback = {
            self.removeSubviews()
            self.isPresenting = false
            self.popupView.transform = CGAffineTransform.identity
            
            if self.didDismiss != nil {
                self.didDismiss!(self)
            }
        }
        
        let animOpts: (LTMPopupSlideStyle) -> UIView.AnimationOptions = { slide in
            if slide != .ShrinkInOut1 {
                return .curveLinear
            }
            return .curveEaseInOut
        }
        
        if isSpringAnimated {
            let duration1 = duration * 0.25 * 0.75, duration2 = duration * 0.75 - duration1
            UIView.animate(withDuration: duration1, delay: 0, options: .curveEaseInOut, animations: {
                self.bufferBackground()
                self.popupView.center = self.bufferCenter(move: 30)
            }) { (finished) in
                UIView.animate(withDuration: duration2, delay: 0, options:animOpts(self.slideStyle), animations: {
                    self.dismissedDropAnimated()
                    self.dismissedBackground()
                }, completion: { (finished) in
                    if finished {
                        dismissCallback()
                    }
                })
            }
        } else {
            UIView.animate(withDuration: duration, delay: 0, options: animOpts(self.slideStyle), animations: {
                self.dismissedDropAnimated()
                self.dismissedBackground()
                self.popupView.center = self.dismissedCenter()
            }) { (finished) in
                if finished {
                    dismissCallback()
                }
            }
        }
    }
    
    @objc private func innerDismiss() {
        _dismiss(duration: duration ?? 0.0, isSpringAnimated: isSpringAnimated)
    }
    
    private func _fadeDismiss() {
        slideStyle = .Fade
        innerDismiss()
    }
    
}

public extension LTMPopupVC {
    func popupController(maskType: LTMPopupMaskType) -> LTMPopupVC {
        return LTMPopupVC(maskType: maskType)
    }
    
    /// present your conteent view
    ///
    /// - Parameters:
    ///   - contentView: This is the view that you want to appear in popup.
    ///   - duration: Popup animation time.
    ///   - isSpringAnimated: if YES, Will use a spring animation.
    ///   - inView: Displayed on the sView. if nil, Displayed on the window.
    ///   - displayTime: The view will disappear after `displayTime` seconds.
    func present(contentView: UIView, duration: TimeInterval, isSpringAnimated: Bool, inView: UIView?, displayTime: TimeInterval) {
        _present(contentView: contentView, duration: duration, isSpringAnimated: isSpringAnimated, inView: inView, displayTime: displayTime)
    }
    
    func present(contentView: UIView, duration: TimeInterval, isSpringAnimated: Bool, inView: UIView?) {
        present(contentView: contentView, duration: duration, isSpringAnimated: isSpringAnimated, inView: inView, displayTime: 0)
    }
    
    func present(contentView: UIView, duration: TimeInterval, isSpringAnimated: Bool) {
        present(contentView: contentView, duration: duration, isSpringAnimated: isSpringAnimated, inView: nil)
    }
    
    func present(contentView: UIView, duration: TimeInterval) {
        present(contentView: contentView, duration: duration, isSpringAnimated: false)
    }
    
    func present(contentView: UIView) {
        present(contentView: contentView, duration: 0.25)
    }
    
    func dismiss(duration: TimeInterval, isSpringAnimated: Bool) {
        _dismiss(duration: duration, isSpringAnimated: isSpringAnimated)
    }
    
    func dismiss() {
        innerDismiss()
    }
    
    func fadeDismiss() {
        _fadeDismiss()
    }
    
    /// set mask view of transparency, default is 0.5, layoutType = .Center is vaild
    func set(maskAlpha: CGFloat) {
        if maskType != .BlackTranslucent {
            return
        }
        self.maskAlpha = maskAlpha
        maskView.backgroundColor = UIColor(white: 0.0, alpha: maskAlpha)
    }
    
    func set(allowPan: Bool) {
        if !allowPan {
            return
        }
        if self.allowPan != allowPan {
            self.allowPan = allowPan
            let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
            popupView.addGestureRecognizer(pan)
        }
    }
    
    /// Use drop animation and set the rotation Angle. if set, Will not support drag.
    func setDropAnimated(angle: CGFloat) {
        dropAngle = angle
        slideStyle = .Top
    }
}

public extension UIViewController {
    private struct AssociatedKey {
        static var key: String = "WCPpupControllerKey"
    }
    var ltm_popupController: LTMPopupVC {
        set {
            objc_setAssociatedObject(self, &AssociatedKey.key, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            var popupController = objc_getAssociatedObject(self, &AssociatedKey.key) as? LTMPopupVC
            if popupController == nil {
                popupController = LTMPopupVC()
                self.ltm_popupController = popupController!
            }
            return popupController!
        }
    }
}
