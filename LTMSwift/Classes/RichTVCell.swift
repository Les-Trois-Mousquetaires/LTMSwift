//
//  RichTVCell.swift
//  Alamofire
//
//  Created by zsn on 2022/12/4.
//

import YYText
import SnapKit

class RichTVCell: UITableViewCell {
    /// 响应key
    var enentBlock: (() -> Void)?
    
    private var attrModel = RichModel()
    /// 富文本模型
    var model: RichModel {
        set{
            self.attrModel = newValue
            self.backgroundColor = self.attrModel.cellColor
            self.dividerView.backgroundColor = self.attrModel.lineColor
            self.titleRichLabel.attributedText =  self.attrModel.key
            if (self.attrModel.type == .richLabel){
                self.valueTextField.isHidden = true
                self.valueRichLabel.isHidden = false
                self.valueTextField.text =  ""
                self.valueRichLabel.attributedText =  self.attrModel.value
            }else if (self.attrModel.type == .textfield){
                self.valueTextField.isHidden = false
                self.valueRichLabel.isHidden = true
                if (self.attrModel.value.string.count > 0){
                    self.valueTextField.attributedText =  self.attrModel.value
                }else{
                    self.valueTextField.attributedPlaceholder =  self.attrModel.placeHolder
                    self.valueTextField.textColor = self.attrModel.textFieldTextColor
                    self.valueTextField.font = self.attrModel.textFieldFont
                }
                self.valueRichLabel.text =  ""
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
    }
    
    @objc func click(){
        guard let block = self.enentBlock else{
            return
        }
        block()
    }
        
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private lazy var titleRichLabel: YYLabel = {
       let label = YYLabel()
        label.isUserInteractionEnabled = true
        
        return label
    }()
    
    private lazy var valueRichLabel: YYLabel = {
       let label = YYLabel()
        label.textAlignment = .right
        label.isUserInteractionEnabled = true
        label.numberOfLines = 0
        
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
