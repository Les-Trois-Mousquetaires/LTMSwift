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

public enum LTMHUDQueueOverflowStrategy {
    case dropOldest
    case dropNewest
}

open class LTMHUDManage: NSObject {
    // MARK: - HUD相关
    static let instance: LTMHUDManage = LTMHUDManage()
    /// 是否接收事件 默认不接收 如果显示是想屏蔽事件需要把 isReceiveEvent = true
    static var isReceiveEvent = false
    /// HUD 队列上限（不包含 loading 单槽）。
    public static var maxQueueCount: Int = 20
    /// 连续重复提示的去重时间窗口，0 表示关闭去重。
    public static var deduplicateInterval: TimeInterval = 0.8
    /// 队列超限时的丢弃策略。
    public static var overflowStrategy: LTMHUDQueueOverflowStrategy = .dropOldest

    /// 样式配置
    public static var contentInset: CGFloat = hudreserved
    public static var maxTextWidth: CGFloat = hudmaxWidth
    public static var iconSize: CGFloat = hudiconWH
    public static var labelFontSize: CGFloat = hudlabelSize
    public static var lineSpacing: CGFloat = hudlineSpacing

    public class var shared: LTMHUDManage {
        return instance
    }
    
    /// 加载HUD
    /// - Parameter name: 提示语
   public func ltm_showLoading(_ name: String = "正在加载",_ time: TimeInterval? = nil, interruptCurrent: Bool = false) {
        if time == nil {
            LTMProgressHUD.show(.loading, name, 60, interruptCurrent: interruptCurrent)
        } else {
            LTMProgressHUD.show(.loading, name, time ?? 1, interruptCurrent: interruptCurrent)
        }
    }
    
    /**
     只显示文字
     
     - parameter name 提示语
     - parameter delay 延迟时间
     */
    public func ltm_showtitle(_ name: String?,_ delay: TimeInterval = 1, priority: Int = 0, interruptCurrent: Bool = false) {
        LTMProgressHUD.show(.none, name ?? "", delay, priority: priority, interruptCurrent: interruptCurrent)
    }

    /**
     显示警告
     
     - parameter name 提示语
     - parameter delay 延迟时间
     */
    public func ltm_showInfo(_ name: String?,_ delay: TimeInterval = 1, priority: Int = 0, interruptCurrent: Bool = false) {
        LTMProgressHUD.show(.info, name ?? "", delay, priority: priority, interruptCurrent: interruptCurrent)
    }

    /// 隐藏当前 HUD（会继续展示队列中的下一条）
    public func ltm_dismiss() {
        LTMProgressHUD.dismiss()
    }

    /// 清空等待队列（不影响当前正在显示的 HUD）
    public func ltm_clearQueue() {
        LTMProgressHUD.clearQueue()
    }

    /// 立即关闭所有 HUD 并清空队列
    public func ltm_dismissAll() {
        LTMProgressHUD.dismissAll()
    }

    /// 当前等待队列数量（不包含当前正在显示的 HUD）
    public var ltm_pendingCount: Int {
        LTMProgressHUD.pendingCount
    }

    /// 成功提示
    public func ltm_showSuccess(_ name: String, priority: Int = 0, interruptCurrent: Bool = false) {
        LTMProgressHUD.show(.success, name, 1, priority: priority, interruptCurrent: interruptCurrent)
    }

    /// 失败提示
    public func ltm_showError(_ name: String, priority: Int = 0, interruptCurrent: Bool = false) {
        LTMProgressHUD.show(.error, name, 1, priority: priority, interruptCurrent: interruptCurrent)
    }

}

public extension UIViewController {
    /// HUD管理者，使用 `HUDManage.ltm_showtitle("HUD")`
    var HUDManage: LTMHUDManage {
        LTMHUDManage.shared
    }
}

public extension UIView {
    /// HUD管理者，使用 `HUDManage.ltm_showtitle("HUD")`
    var HUDManage: LTMHUDManage {
        LTMHUDManage.shared
    }
}

public typealias HUDCompletedBlock = () -> Void

private struct LTMHUDTask {
    let id: UInt64
    let type: LTMProgressHUDType
    let text: String
    let time: TimeInterval
    let priority: Int
    let completion: HUDCompletedBlock?

    var dedupKey: String {
        "\(type)-\(text)"
    }
}

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
    class func show(_ type: LTMProgressHUDType,_ text: String,_ time: TimeInterval = 1, priority: Int = 0, interruptCurrent: Bool = false, completion: HUDCompletedBlock? = nil) {
        if !Thread.isMainThread {
            DispatchQueue.main.async {
                show(type, text, time, priority: priority, interruptCurrent: interruptCurrent, completion: completion)
            }
            return
        }

        idSeed += 1
        let task = LTMHUDTask(id: idSeed, type: type, text: text, time: time, priority: priority, completion: completion)
        if interruptCurrent {
            interruptAndPresent(task)
        } else {
            enqueueOrPresent(task)
        }
    }


    private class func interruptAndPresent(_ task: LTMHUDTask) {
        if isDuplicate(task) {
            return
        }

        dismissCurrent(callCompletion: false, presentNext: false)
        present(task)
    }

    class var pendingCount: Int {
        pendingTasks.count + (pendingLoadingTask == nil ? 0 : 1)
    }

    class func clearQueue() {
        if !Thread.isMainThread {
            DispatchQueue.main.async { clearQueue() }
            return
        }
        pendingTasks.removeAll(keepingCapacity: false)
        pendingLoadingTask = nil
        lastEnqueueTimestamp.removeAll(keepingCapacity: false)
    }

    class func dismissAll() {
        if !Thread.isMainThread {
            DispatchQueue.main.async { dismissAll() }
            return
        }
        clearQueue()
        dismissCurrent(callCompletion: false, presentNext: false)
    }

    private class func enqueueOrPresent(_ task: LTMHUDTask) {
        if isDuplicate(task) {
            return
        }

        if task.type == .loading {
            if currentTask == nil {
                present(task)
                return
            }

            if currentTask?.type == .loading {
                dismissCurrent(callCompletion: false, presentNext: false)
                present(task)
                return
            }

            pendingLoadingTask = task
            return
        }

        if currentTask != nil {
            insertPendingTask(task)
            trimPendingQueueIfNeeded()
            return
        }

        present(task)
    }

    private class func insertPendingTask(_ task: LTMHUDTask) {
        let index = pendingTasks.firstIndex(where: { existing in
            if task.priority == existing.priority {
                return task.id < existing.id
            }
            return task.priority > existing.priority
        })

        if let index {
            pendingTasks.insert(task, at: index)
        } else {
            pendingTasks.append(task)
        }
    }

    private class func trimPendingQueueIfNeeded() {
        let maxCount = max(1, LTMHUDManage.maxQueueCount)
        while pendingTasks.count > maxCount {
            switch LTMHUDManage.overflowStrategy {
            case .dropOldest:
                if let index = pendingTasks.indices.min(by: { pendingTasks[$0].id < pendingTasks[$1].id }) {
                    pendingTasks.remove(at: index)
                } else {
                    pendingTasks.removeFirst()
                }
            case .dropNewest:
                if let index = pendingTasks.indices.max(by: { pendingTasks[$0].id < pendingTasks[$1].id }) {
                    pendingTasks.remove(at: index)
                } else {
                    pendingTasks.removeLast()
                }
            }
        }
    }

    private class func isDuplicate(_ task: LTMHUDTask) -> Bool {
        guard LTMHUDManage.deduplicateInterval > 0 else { return false }

        let now = Date().timeIntervalSince1970
        pruneDedupCache(now: now)
        if let timestamp = lastEnqueueTimestamp[task.dedupKey], now - timestamp <= LTMHUDManage.deduplicateInterval {
            return true
        }

        if currentTask?.dedupKey == task.dedupKey { return true }
        if pendingTasks.contains(where: { $0.dedupKey == task.dedupKey }) { return true }
        if pendingLoadingTask?.dedupKey == task.dedupKey { return true }

        lastEnqueueTimestamp[task.dedupKey] = now
        return false
    }

    private class func pruneDedupCache(now: TimeInterval) {
        let expiration = max(10, LTMHUDManage.deduplicateInterval * 5)
        lastEnqueueTimestamp = lastEnqueueTimestamp.filter { now - $0.value <= expiration }

        let maxCacheSize = 512
        if lastEnqueueTimestamp.count > maxCacheSize {
            let sorted = lastEnqueueTimestamp.sorted { $0.value < $1.value }
            let overflow = lastEnqueueTimestamp.count - maxCacheSize
            for i in 0..<overflow {
                lastEnqueueTimestamp.removeValue(forKey: sorted[i].key)
            }
        }
    }

    private class func present(_ task: LTMHUDTask) {
        currentTask = task
        instance.registerDeviceOrientationNotification()
        var isNone: Bool = false

        let reserved = LTMHUDManage.contentInset
        let iconSize = LTMHUDManage.iconSize
        let fontSize = LTMHUDManage.labelFontSize
        let lineSpacing = LTMHUDManage.lineSpacing
        let maxTextWidth = min(LTMHUDManage.maxTextWidth, UIScreen.main.bounds.width - 40)

        let window = UIWindow()
        window.backgroundColor = UIColor.clear
        let mainView = UIView()
        mainView.layer.cornerRadius = 10
        mainView.backgroundColor = UIColor(red:0, green:0, blue:0, alpha: 0.7)

        var image = UIImage()
        var headView = UIView()
        switch task.type {
        case .success:
            image = imageOfCheckmark
        case .error:
            image = imageOfCross
        case .info:
            image = imageOfInfo
        default:
            break
        }

        switch task.type {
        case .loading:
            let indicator = UIActivityIndicatorView(style: .large)
            indicator.startAnimating()
            headView = indicator
            headView.translatesAutoresizingMaskIntoConstraints = false
            mainView.addSubview(headView)
        case .success, .error, .info:
            headView = UIImageView(image: image)
            headView.translatesAutoresizingMaskIntoConstraints = false
            mainView.addSubview(headView)
        case .none:
            isNone = true
        }

        let label = UILabel()
        label.text = task.text
        label.numberOfLines = 0
        label.lineBreakMode = .byTruncatingTail
        label.font = UIFont.systemFont(ofSize: fontSize)
        label.textColor = UIColor.white
        label.translatesAutoresizingMaskIntoConstraints = false
        let arr = NSMutableAttributedString(string: task.text).hud_addLineSpacing(lineSpacing)
        label.attributedText = arr

        let screenHeight = UIScreen.main.bounds.height
        let maxHUDHeight = max(120, screenHeight - 40)
        let maxTextHeight: CGFloat = isNone
            ? max(0, maxHUDHeight - reserved * 2)
            : max(0, maxHUDHeight - reserved * 3 - iconSize)

        let lineHeight = max(1, label.font.lineHeight + lineSpacing)
        label.numberOfLines = max(1, Int(floor(maxTextHeight / lineHeight)))

        var textHeight: CGFloat = task.text.count > 0 ? arr.hud_getHeight(maxTextWidth) : 0
        textHeight = min(textHeight + textHeight / label.font.pointSize * lineSpacing, maxTextHeight)

        var width = arr.hud_getWidth(CGFloat(MAXFLOAT), maxTextWidth)
        var height = textHeight
        if !isNone {
            width = height > 0 ? width : iconSize
            height = height > 0 ? height + iconSize + reserved : iconSize
        }
        label.textAlignment = .center
        mainView.addSubview(label)

        let containerMaxHeight = max(120, UIScreen.main.bounds.height - 40)
        let containerHeight = min(height + reserved * 2, containerMaxHeight)

        if LTMHUDManage.isReceiveEvent == false {
            window.frame = UIScreen.main.bounds
            mainView.frame = CGRect(x: (UIScreen.main.bounds.size.width - (width + reserved * 4)) / 2,
                                    y: (UIScreen.main.bounds.size.height - containerHeight) / 2,
                                    width: width + reserved * 4,
                                    height: containerHeight)
        } else {
            let superFrame = CGRect(x: 0, y: 0, width: width + reserved * 4, height: containerHeight)
            window.frame = superFrame
            mainView.frame = superFrame
        }

        if !isNone {
            mainView.addConstraint(NSLayoutConstraint(item: headView, attribute: .top, relatedBy: .lessThanOrEqual, toItem: mainView, attribute: .top, multiplier: 1, constant: reserved))
            mainView.addConstraint(NSLayoutConstraint(item: headView, attribute: .centerX, relatedBy: .equal, toItem: mainView, attribute: .centerX, multiplier: 1.0, constant: 0))
            mainView.addConstraint(NSLayoutConstraint(item: headView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: iconSize))
            mainView.addConstraint(NSLayoutConstraint(item: headView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: iconSize))
        }

        if !isNone {
            let labelTop = reserved + iconSize + reserved
            mainView.addConstraint(NSLayoutConstraint(item: label, attribute: .top, relatedBy: .lessThanOrEqual, toItem: mainView, attribute: .top, multiplier: 1, constant: labelTop))
        } else {
            mainView.addConstraint(NSLayoutConstraint(item: label, attribute: .centerY, relatedBy: .lessThanOrEqual, toItem: mainView, attribute: .centerY, multiplier: 1, constant: 0))
        }

        mainView.addConstraint(NSLayoutConstraint(item: label, attribute: .centerX, relatedBy: .equal, toItem: mainView, attribute: .centerX, multiplier: 1.0, constant: 0))
        mainView.addConstraint(NSLayoutConstraint(item: label, attribute: .width, relatedBy: .lessThanOrEqual, toItem: nil, attribute: .width, multiplier: 1.0, constant: maxTextWidth))
        mainView.addConstraint(NSLayoutConstraint(item: label, attribute: .height, relatedBy: .greaterThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 0))

        if #available(iOS 13.0, *) {
            window.windowScene = UIApplication.shared.curWindowScene
        }
        window.windowLevel = UIWindow.Level.alert
        window.center = getCenter()
        window.isHidden = false
        window.addSubview(mainView)
        windowsTemp.append(window)

        if task.time != 0 {
            delayDismiss(task.time)
        }
    }
    
    class func dismiss() {
        if !Thread.isMainThread {
            DispatchQueue.main.async {
                dismiss()
            }
            return
        }

        dismissCurrent(callCompletion: false)
    }

    private class func dismissCurrent(callCompletion: Bool, presentNext: Bool = true) {
        dismissWorkItem?.cancel()
        dismissWorkItem = nil
        instance.removeDeviceOrientationNotification()
        if let currentwindow = windowsTemp.last {
            for view in currentwindow.subviews {
                view.removeFromSuperview()
            }
        }
        windowsTemp.removeAll(keepingCapacity: false)

        let completion = currentTask?.completion
        currentTask = nil

        if callCompletion {
            completion?()
        }

        guard presentNext else { return }

        if let loadingTask = pendingLoadingTask {
            pendingLoadingTask = nil
            present(loadingTask)
            return
        }

        if let nextTask = pendingTasks.first {
            pendingTasks.removeFirst()
            present(nextTask)
        }
    }
}

open class LTMProgressHUD: NSObject {
    fileprivate static var windowsTemp = [UIWindow]()
    fileprivate static var dismissWorkItem: DispatchWorkItem?
    fileprivate static var pendingTasks: [LTMHUDTask] = []
    fileprivate static var pendingLoadingTask: LTMHUDTask?
    fileprivate static var currentTask: LTMHUDTask?
    fileprivate static var idSeed: UInt64 = 0
    fileprivate static var lastEnqueueTimestamp: [String: TimeInterval] = [:]
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
    fileprivate class func delayDismiss(_ time: TimeInterval) {
        guard time > 0 else { return }

        dismissWorkItem?.cancel()
        let workItem = DispatchWorkItem {
            dismissCurrent(callCompletion: true)
        }
        dismissWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + time, execute: workItem)
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
        if let image = Cache.imageOfCheckmark {
            return image
        }
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 36, height: 36), false, 0)
        LTMProgressHUD.draw(.success)
        Cache.imageOfCheckmark = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return Cache.imageOfCheckmark ?? UIImage()
    }
    // MARK: - 画X
    fileprivate class var imageOfCross: UIImage {
        if let image = Cache.imageOfCross {
            return image
        }
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 36, height: 36), false, 0)
        LTMProgressHUD.draw(.error)
        Cache.imageOfCross = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return Cache.imageOfCross ?? UIImage()
    }
    // MARK: - 画!
    fileprivate class var imageOfInfo: UIImage {
        if let image = Cache.imageOfInfo {
            return image
        }
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 36, height: 36), false, 0)
        LTMProgressHUD.draw(.info)
        Cache.imageOfInfo = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return Cache.imageOfInfo ?? UIImage()
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
