//
//  RichTVCell.swift
//  LTMSwift
//
//  Created by zsn on 2022/12/4.
//

import YYText
import SnapKit

open class RichTVCell: UITableViewCell {
    /// 响应key
    var eventBlock: (() -> Void)?
    /// 输入框响应key
    var textFieldEvnentBlock: ((_ text: String) -> Void)?

    private var attrModel = RichModel()
    /// 富文本模型
    var model: RichModel {
        set{
            self.attrModel = newValue
            self.titleRichLabel.text =  ""
            self.valueRichLabel.text =  ""
            self.valueTextField.text =  ""
            self.backgroundColor = self.attrModel.cellColor
            self.dividerView.backgroundColor = self.attrModel.lineColor
            self.titleRichLabel.attributedText =  self.attrModel.key
            if (self.attrModel.type == .richLabel){
                self.valueTextField.isHidden = true
                self.valueRichLabel.isHidden = false
                self.valueRichLabel.textAlignment = self.attrModel.valueTextAlignment
                if (self.attrModel.titleWidth > 0){
                    self.titleRichLabel.snp.remakeConstraints { make in
                        make.top.bottom.equalTo(self.contentView)
                        make.left.equalTo(self.contentView).offset(self.attrModel.space).priority(.high)
                        make.width.equalTo(self.attrModel.titleWidth).priority(.high)
                    }
                }else{
                    self.titleRichLabel.snp.remakeConstraints { make in
                        make.top.bottom.equalTo(self.contentView)
                        make.left.equalTo(self.contentView).offset(self.attrModel.space)
                    }
                }
                if (self.attrModel.alignment == .left){
                    self.valueRichLabel.textAlignment = .left
                    self.valueRichLabel.snp.remakeConstraints { make in
                        make.top.bottom.equalTo(self.contentView)
                        make.left.equalTo(self.titleRichLabel.snp.right)
                        make.right.equalTo(self.contentView).offset(-self.attrModel.space)
                    }
                }else{
                    self.valueRichLabel.textAlignment = .right
                    self.valueRichLabel.snp.remakeConstraints { make in
                        make.top.bottom.equalTo(self.contentView)
                        make.left.greaterThanOrEqualTo(self.titleRichLabel.snp.right).offset(14)
                        make.right.equalTo(self.contentView).offset(-self.attrModel.space)
                    }
                }
                self.valueRichLabel.attributedText =  self.attrModel.value

            }else if (self.attrModel.type == .textfield){
                self.valueTextField.keyboardType = self.attrModel.keyboard
                self.valueTextField.isHidden = false
                self.valueRichLabel.isHidden = true
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
        self.contentView.addSubViews([self.titleRichLabel,self.valueRichLabel,self.valueTextField,
                                      self.dividerView])
        self.titleRichLabel.snp.makeConstraints { make in
            make.top.bottom.equalTo(self.contentView)
            make.left.equalTo(self.contentView).offset(10)
        }
        self.valueRichLabel.snp.makeConstraints { make in
            make.top.bottom.equalTo(self.contentView)
            make.left.greaterThanOrEqualTo(self.titleRichLabel.snp.right).offset(14)
            make.right.equalTo(self.contentView).offset(-10)
        }
        self.valueTextField.snp.makeConstraints { make in
            make.top.bottom.equalTo(self.contentView)
            make.left.greaterThanOrEqualTo(self.titleRichLabel.snp.right).offset(14)
            make.right.equalTo(self.contentView).offset(-10)
            make.width.greaterThanOrEqualTo(100)
        }
        self.dividerView.snp.makeConstraints { make in
            make.left.equalTo(self.contentView).offset(14)
            make.bottom.right.equalTo(self.contentView)
            make.height.equalTo(1)
        }
        let tapGes = UITapGestureRecognizer(target: self, action: #selector(click))
        self.contentView.addGestureRecognizer(tapGes)
        self.valueTextField.addTarget(self, action: #selector(phoneTextFieldChange(_:)), for: .editingChanged)
    }
    
    @objc func phoneTextFieldChange(_ textfield: UITextField){
        guard let block = self.textFieldEvnentBlock else{
            return
        }
        block(textfield.text ?? "")
    }
    
    @objc func click(){
        guard let block = self.eventBlock else{
            return
        }
        block()
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
    
    private lazy var valueRichLabel: YYLabel = {
        let label = YYLabel()
         label.textAlignment = .right
         label.isUserInteractionEnabled = true
         label.numberOfLines = 0
         label.setContentHuggingPriority(.defaultLow, for: .horizontal)
         label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
         
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
