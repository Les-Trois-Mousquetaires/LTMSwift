//
//  RichTextFieldTVCell.swift
//  LTMSwift
//
//  Created by zsn on 2023/11/14.
//

import YYText
import SnapKit

open class RichTextFieldTVCell: UITableViewCell {
    /// 输入框响应key
    public var textFieldEvnentBlock: ((_ text: String) -> Void)?
    
    private var attrModel = RichTextFieldModel()
    /// 富文本模型
    public var model: RichModel {
        set{
            
            if newValue.type != .textfield {
                return
            }
            guard let textFieldModel = newValue as? RichTextFieldModel else {
                return
            }
            self.attrModel = textFieldModel
            self.titleRichLabel.text =  ""
            self.valueTextField.text =  ""
            self.backgroundColor = self.attrModel.cellColor
            self.dividerView.backgroundColor = self.attrModel.lineColor
            self.titleRichLabel.attributedText =  self.attrModel.key
            self.valueTextField.keyboardType = self.attrModel.keyboard
            self.valueTextField.isEnabled = self.attrModel.isEnabled
            if (self.attrModel.value.string.count > 0){
                self.valueTextField.attributedText =  self.attrModel.value
            }else{
                self.valueTextField.textColor = self.attrModel.textFieldTextColor
                self.valueTextField.font = self.attrModel.textFieldFont
            }
            self.valueTextField.attributedPlaceholder =  self.attrModel.placeHolder
            if (self.attrModel.maxLength >= 0){
                self.valueTextField.maxLength = self.attrModel.maxLength
            }
            if (self.attrModel.maxNumber.doubleValue >= 0){
                self.valueTextField.maxNumber = self.attrModel.maxNumber
            }
            if (self.attrModel.digits >= 0){
                self.valueTextField.digits = self.attrModel.digits
            }
            if ((self.attrModel.limitBlock) != nil){
                self.valueTextField.limitBlock = self.attrModel.limitBlock
            }
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
                                      self.valueTextField,
                                      self.dividerView])
        self.titleRichLabel.snp.makeConstraints { make in
            make.top.bottom.equalTo(self.contentView)
            make.left.equalTo(self.contentView).offset(14)
        }
        self.valueTextField.snp.makeConstraints { make in
            make.top.bottom.equalTo(self.contentView)
            make.left.equalTo(self.titleRichLabel.snp.right).offset(14)
            make.right.equalTo(self.contentView).offset(-14)
        }
        self.dividerView.snp.makeConstraints { make in
            make.left.equalTo(self.contentView).offset(14)
            make.bottom.right.equalTo(self.contentView)
            make.height.equalTo(1)
        }
        self.valueTextField.addTarget(self, action: #selector(phoneTextFieldChange(_:)), for: .editingChanged)
    }
    
    @objc func phoneTextFieldChange(_ textfield: UITextField){
        guard let block = self.textFieldEvnentBlock else{
            return
        }
        block(textfield.text ?? "")
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private lazy var titleRichLabel: YYLabel = {
        let label = YYLabel()
        label.numberOfLines = 0
        label.isUserInteractionEnabled = true
        label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        label.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        
        return label
    }()
    
    private lazy var valueTextField: UITextField = {
        let textField = UITextField()
        textField.textAlignment = .right
        
        return textField
    }()
    
    private lazy var dividerView: UIView = {
        let view = UIView()
        
        return view
    }()
}
