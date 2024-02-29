//
//  TextSwitch.swift
//  Alamofire
//
//  Created by zsn on 2023/8/9.
//

import Foundation
import AudioToolbox

//MARK: - TextSwitch
public extension TextSwitch {
    /// 开的背景颜色
    var onTintColor: UIColor {
        set{
            self.onContainerView.backgroundColor = newValue
        }get{
            .clear
        }
    }
    
    /// 开的字体颜色
    var onTextColor: UIColor {
        set{
            self.onLabel.textColor = newValue
        }get{
            .white
        }
    }
    
    /// 开的文字
    var onText: String {
        set{
            self.onLabel.text = newValue
        }get{
            ""
        }
    }
    
    /// 关的背景颜色
    var offTintColor: UIColor {
        set{
            self.offContainerView.backgroundColor = newValue
        }get{
            .gray
        }
    }
    
    /// 关的字体颜色
    var offTextColor: UIColor {
        set{
            self.offLabel.textColor = newValue
        }get{
            .white
        }
    }
    
    /// 关的文字
    var offText: String {
        set{
            self.offLabel.text = newValue
        }get{
            ""
        }
    }
    
    /// 开关的字号
    var textFont: UIFont {
        set{
            self.onLabel.font = newValue
            self.offLabel.font = newValue
        }get{
            .systemFont(ofSize: 14, weight: .regular)
        }
    }
    
    /// 开关圆形部位的颜色
    var thumbTintColor: UIColor {
        set{
            self.thumbTintView.backgroundColor = newValue
        }get{
            .white
        }
    }
}

open class TextSwitch: UIControl {
    /// 大小 圆大小
    let SwitchWidth = 67.0, SwitchHeight = 32.0, ThumbTintWidth = 24.0
    /// 动画时间
    let AnimatedTime = 0.3
    
    /// 是否有震动效果
    public var hasShake = true
    
    private var curStatus = false
    /// 获取开关状态
    public var isOn: Bool{
        return self.curStatus
    }
    
    /// 设置开关状态 有动画
    public var setOn: Bool {
        set{
            self.curStatus = newValue
            self.configHasAnimated(self.curStatus)
        }get{
            self.curStatus
        }
    }
    
    /// 设置开关状态 无动画
    public var setNoAnimatedOn: Bool {
        set{
            self.curStatus = newValue
            self.configNoAnimated(self.curStatus)
        }get{
            self.curStatus
        }
    }
    
    public override init(frame: CGRect) {
        super.init(frame: CGRect(x: 0, y: 0, width: SwitchWidth, height: SwitchHeight))
        configUI()
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapClick(_ :)))
        self.addGestureRecognizer(tap)
        let pan = UIPanGestureRecognizer(target: self, action: #selector(panClick(_ :)))
        self.addGestureRecognizer(pan)
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// 容器
    private lazy var containerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 16
        view.layer.masksToBounds = true
        
        return view
    }()
    
    /// 开容器
    private lazy var onContainerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 16
        view.layer.masksToBounds = true
        
        return view
    }()
    
    /// 关容器
    private lazy var offContainerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 16
        view.layer.masksToBounds = true
        
        return view
    }()
    
    /// 开关圆形部位
    private lazy var thumbTintView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 12
        view.layer.masksToBounds = true
        
        return view
    }()
    
    /// 开
    private lazy var onLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.isUserInteractionEnabled = true
        
        return label
    }()
    
    // 关
    private lazy var offLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .right
        label.isUserInteractionEnabled = true
        
        return label
    }()
}

//MARK: - Event
@objc private extension TextSwitch {
    
    private func configHasAnimated(_ on: Bool){
        let margin = (SwitchHeight - ThumbTintWidth) / 2
        let thumbTintWidth = ThumbTintWidth
        let switchWidth = SwitchWidth
        let switchHeight = SwitchHeight
        
        if(on){
            UIView.animate(withDuration: AnimatedTime) {[weak self] in
                self?.thumbTintView.frame = CGRect(x: switchWidth - margin - thumbTintWidth, y: margin, width: thumbTintWidth, height: thumbTintWidth)
            } completion: {[weak self] result in
                self?.onContainerView.frame = CGRect(x: 0, y: 0, width: switchWidth, height: switchHeight)
                self?.offContainerView.frame = CGRect(x: switchWidth, y: 0, width: switchWidth, height: switchHeight)
            }
        }else{
            UIView.animate(withDuration: AnimatedTime) {[weak self] in
                self?.thumbTintView.frame = CGRect(x: margin, y: margin, width: thumbTintWidth, height: thumbTintWidth)
            } completion: {[weak self] result in
                self?.onContainerView.frame = CGRect(x: -switchWidth, y: 0, width: switchWidth, height: switchHeight)
                self?.offContainerView.frame = CGRect(x: 0, y: 0, width: switchWidth, height: switchHeight)
            }
        }
    }
    private func configNoAnimated(_ on: Bool){
        let margin = (SwitchHeight - ThumbTintWidth) / 2
        let thumbTintWidth = ThumbTintWidth
        let switchWidth = SwitchWidth
        let switchHeight = SwitchHeight
        
        if(on){
            UIView.animate(withDuration: 0.01) {[weak self] in
                self?.thumbTintView.frame = CGRect(x: switchWidth - margin - thumbTintWidth, y: margin, width: thumbTintWidth, height: thumbTintWidth)
            } completion: {[weak self] result in
                self?.onContainerView.frame = CGRect(x: 0, y: 0, width: switchWidth, height: switchHeight)
                self?.offContainerView.frame = CGRect(x: switchWidth, y: 0, width: switchWidth, height: switchHeight)
            }
        }else{
            UIView.animate(withDuration: 0.01) {[weak self] in
                self?.thumbTintView.frame = CGRect(x: margin, y: margin, width: thumbTintWidth, height: thumbTintWidth)
            } completion: {[weak self] result in
                self?.onContainerView.frame = CGRect(x: -switchWidth, y: 0, width: switchWidth, height: switchHeight)
                self?.offContainerView.frame = CGRect(x: 0, y: 0, width: switchWidth, height: switchHeight)
            }
        }
    }
    
    @objc private func tapClick(_ gesture: UITapGestureRecognizer) {
        if (gesture.state == .ended){
            self.setOn = !self.curStatus
            if(self.hasShake){
                AudioServicesPlaySystemSoundWithCompletion(SystemSoundID(1520)) {
                }
            }
            self.sendActions(for: .valueChanged)
        }
    }
    
    @objc private func panClick(_ gesture: UIPanGestureRecognizer) {
        let margin = (SwitchHeight - ThumbTintWidth) / 2
        let thumbTintWidth = ThumbTintWidth
        let switchWidth = SwitchWidth
        switch gesture.state {
        case .possible:
            break
        case .began:
            if(self.isOn){
                UIView.animate(withDuration: AnimatedTime) {[weak self] in
                    self?.thumbTintView.frame = CGRect(x: switchWidth - margin - thumbTintWidth, y: margin, width: thumbTintWidth, height: thumbTintWidth)
                }
            }else{
                UIView.animate(withDuration: AnimatedTime) {[weak self] in
                    self?.thumbTintView.frame = CGRect(x: margin, y: margin, width: thumbTintWidth, height: thumbTintWidth)
                }
            }
        case .changed:
            break
        case .ended:
            self.setOn = !self.curStatus
            if(self.hasShake){
                AudioServicesPlaySystemSoundWithCompletion(SystemSoundID(1520)) {
                }
            }
            self.sendActions(for: .valueChanged)
        case .cancelled:
            break
        case .failed:
            if(self.isOn){
                UIView.animate(withDuration: AnimatedTime) {[weak self] in
                    self?.thumbTintView.frame = CGRect(x: switchWidth - thumbTintWidth, y: margin, width: thumbTintWidth, height: thumbTintWidth)
                }
            }else{
                UIView.animate(withDuration: AnimatedTime) {[weak self] in
                    self?.thumbTintView.frame = CGRect(x: margin, y: margin, width: thumbTintWidth, height: thumbTintWidth)
                }
            }
        @unknown default:
            break
        }
    }
}

//MARK: - UI
extension TextSwitch {
    private func configUI() {
        self.backgroundColor = .clear
        self.addSubview(self.containerView)
        self.containerView.addSubview(self.onContainerView)
        self.containerView.addSubview(self.offContainerView)
        self.containerView.addSubview(self.thumbTintView)
        self.onContainerView.addSubview(self.onLabel)
        self.offContainerView.addSubview(self.offLabel)
    }
    
    public override func layoutSubviews() {
        self.containerView.frame = self.bounds
        let margin = (SwitchHeight - ThumbTintWidth) / 2
        if(!self.isOn){
            self.onContainerView.frame = CGRect(x: -SwitchWidth, y: 0, width: SwitchWidth, height: SwitchHeight)
            self.offContainerView.frame = CGRect(x: 0, y: 0, width: SwitchWidth, height: SwitchHeight)
            self.thumbTintView.frame = CGRect(x: margin, y: margin, width: ThumbTintWidth, height: ThumbTintWidth)
        }else{
            self.onContainerView.frame = CGRect(x: 0, y: 0, width: SwitchWidth, height: SwitchHeight)
            self.offContainerView.frame = CGRect(x: SwitchWidth, y: 0, width: SwitchWidth, height: SwitchHeight)
            self.thumbTintView.frame = CGRect(x: SwitchWidth - margin - ThumbTintWidth, y: margin, width: ThumbTintWidth, height: ThumbTintWidth)
        }
        self.onLabel.frame = CGRect(x: SwitchHeight / 2, y: SwitchHeight / 2 - 10, width: 20, height: 20)
        self.offLabel.frame = CGRect(x: SwitchWidth - SwitchHeight / 2 - 20, y: SwitchHeight / 2 - 10, width: 20, height: 20)
    }
}
