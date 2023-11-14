//
//  RichTextSwitchTVCell.swift
//  LTMSwift
//
//  Created by zsn on 2023/11/14.
//

import YYText
import SnapKit

open class RichTextSwitchTVCell: UITableViewCell {
    /// 响应key
    public var textSwitchBlock: ((_ result: Bool) -> Void)?
    
    private var attrModel = RichTextSwitchModel()
    /// 富文本模型
    public var model: RichModel {
        set{
            if newValue.type != .textSwitch {
                return
            }
            guard let textSwitchModel = newValue as? RichTextSwitchModel else {
                return
            }
            self.attrModel = textSwitchModel
            self.titleRichLabel.text =  ""
            self.backgroundColor = self.attrModel.cellColor
            self.dividerView.backgroundColor = self.attrModel.lineColor
            self.titleRichLabel.attributedText =  self.attrModel.key
            
            self.textSwitch.hasShake = self.attrModel.hasShake
            self.textSwitch.onText = self.attrModel.onText
            self.textSwitch.onTextColor = self.attrModel.onTextColor
            self.textSwitch.onTintColor = self.attrModel.onTintColor
            self.textSwitch.offText = self.attrModel.offText
            self.textSwitch.offTextColor = self.attrModel.offTextColor
            self.textSwitch.offTintColor = self.attrModel.offTintColor
            self.textSwitch.setOn = self.attrModel.status
            self.textSwitch.textFont = self.attrModel.textFont
            self.textSwitch.thumbTintColor = self.attrModel.thumbTintColor
            self.textSwitch.alpha = self.attrModel.alpha
            self.textSwitch.isEnabled = self.attrModel.isEnabled
            self.dividerView.isHidden = !self.attrModel.isShowLine
            if self.attrModel.isUpdateLineSpace {
                self.dividerView.snp.remakeConstraints { make in
                    make.left.equalTo(self.contentView).offset(self.attrModel.lineSpace)
                    make.bottom.right.equalTo(self.contentView)
                    make.height.equalTo(1)
                }
            }
        }get{
            self.attrModel
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.contentView.addSubViews([self.titleRichLabel,
                                      self.textSwitch,
                                      self.dividerView])
        self.titleRichLabel.snp.makeConstraints { make in
            make.top.bottom.equalTo(self.contentView)
            make.left.equalTo(self.contentView).offset(14)
            make.right.lessThanOrEqualTo(self.textSwitch.snp.left).offset(-14)
        }
        self.textSwitch.snp.makeConstraints { make in
            make.centerY.equalTo(self.contentView)
            make.right.equalTo(self.contentView).offset(-6)
            make.size.equalTo(CGSize(width: 67, height: 32))
        }
        self.dividerView.snp.makeConstraints { make in
            make.left.equalTo(self.contentView).offset(14)
            make.bottom.right.equalTo(self.contentView)
            make.height.equalTo(1)
        }
        self.textSwitch.addTarget(self, action: #selector(click), for: .valueChanged)
    }
    
    @objc func click(){
        guard let block = self.textSwitchBlock else{
            return
        }
        block(self.textSwitch.isOn)
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private lazy var titleRichLabel: YYLabel = {
        let label = YYLabel()
        label.isUserInteractionEnabled = true
        label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        label.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        
        return label
    }()
    
    private lazy var textSwitch: TextSwitch = {
        let view = TextSwitch()
        
        return view
    }()
    
    private lazy var dividerView: UIView = {
        let view = UIView()
        
        return view
    }()
}
