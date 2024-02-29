//
//  RichLabelImageTVCell.swift
//  LTMSwift
//
//  Created by zsn on 2023/11/14.
//

import YYText
import SnapKit

open class RichLabelImageTVCell: UITableViewCell {
    private var attrModel = RichLabelImageModel()
    /// 富文本模型
    public var model: RichModel {
        set{
            if newValue.type != .richLabelImage {
                return
            }
            guard let labelModel = newValue as? RichLabelImageModel else {
                return
            }
            self.attrModel = labelModel
            self.titleRichLabel.text =  ""
            self.valueRichLabel.text =  ""
            self.rightImageView.image = UIImage(named: self.attrModel.imageName)
            self.backgroundColor = self.attrModel.cellColor
            self.dividerView.backgroundColor = self.attrModel.lineColor
            self.titleRichLabel.attributedText =  self.attrModel.key
            self.valueRichLabel.attributedText =  self.attrModel.value
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
                                      self.valueRichLabel,
                                      self.rightImageView,
                                      self.dividerView])
        self.titleRichLabel.snp.makeConstraints { make in
            make.top.bottom.equalTo(self.contentView)
            make.left.equalTo(self.contentView).offset(14)
        }
        self.valueRichLabel.snp.makeConstraints { make in
            make.top.bottom.equalTo(self.contentView)
            make.left.equalTo(self.titleRichLabel.snp.right).offset(14)
            make.right.equalTo(self.rightImageView.snp.left).offset(-4)
        }
        self.rightImageView.snp.makeConstraints { make in
            make.centerY.equalTo(self.contentView)
            make.size.equalTo(CGSize(width: 24, height: 24))
            make.right.equalTo(self.contentView).offset(-6)
        }
        self.dividerView.snp.makeConstraints { make in
            make.left.equalTo(self.contentView).offset(14)
            make.bottom.right.equalTo(self.contentView)
            make.height.equalTo(1)
        }
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
    
    private lazy var valueRichLabel: YYLabel = {
        let label = YYLabel()
        label.textAlignment = .right
        label.isUserInteractionEnabled = true
        label.numberOfLines = 0
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        
        return label
    }()
    
    private lazy var rightImageView: UIImageView = {
        let view = UIImageView()
        
        return view
    }()
    
    private lazy var dividerView: UIView = {
        let view = UIView()
        
        return view
    }()
}
