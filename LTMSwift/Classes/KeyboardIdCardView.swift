//
//  KeyboardIdCardView.swift
//  LTMSwift
//
//  Created by 柯南 on 2023/2/17.
//

import Foundation
import SnapKit

class KeyboardIdCardView: UIView{
    
    /**
     键盘点击事件
     
     - parameter value 输入的身份证号内容
     - parameter isVaild 身份证号是否真实有效
     */
    var valueBlock: ((_ value: String, _ isVaild: Bool) -> Void)?
    /// 按钮图片
    var deleteImage: UIImage{
        set{
            self.deleteBtn.setImage(newValue)
        }get{
            UIImage()
        }
    }
    /// 按钮背景图片
    var deleteBgImage: UIImage{
        set{
            self.deleteBtn.setBackgroundImage(newValue)
        }get{
            UIImage()
        }
    }
    /// 删除按钮文字
    var deleteTitle: String{
        set{
            self.deleteBtn.setTitle(newValue)
        }get{
            self.deleteBtn.titleLabel?.text ?? ""
        }
    }
    
    /// 删除按钮文字
    var deleteColor: UIColor{
        set{
            self.deleteBtn.setTitleColor(newValue)
        }get{
            self.deleteBtn.titleLabel?.textColor ?? .clear
        }
    }
    
    /// 删除按钮文字字体
    var deleteFont: UIFont{
        set{
            self.deleteBtn.titleLabel?.font = newValue
        }get{
            self.deleteBtn.titleLabel?.font ?? UIFont.systemFont(ofSize: 24, weight: .medium)
        }
    }
    
    /// 响应值
    private var value = ""
    override init(frame: CGRect) {
        super.init(frame: CGRect.init(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 247 + UIApplication.shared.windows[0].safeAreaInsets.bottom))
        self.backgroundColor = .init(hexString: "#D8DADD")
        configUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private lazy var deleteBtn: UIButton = {
        let button = UIButton()
        
        return button
    }()
}

private extension KeyboardIdCardView{
    func configUI(){
        let itemWidth :Int = Int((UIScreen.main.bounds.size.width - 4 * 6) / 3)
        
        for i in 0...10 {
            var showStr: String = "\(i + 1)"
            if i == 9 {
                showStr = "X"
            }
            if i == 10 {
                showStr = "0"
            }
            let button = UIButton()
            button.setTitle(showStr)
            button.setTitleColor(UIColor.black)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 24, weight: .medium)
            button.backgroundColor = .white
            button.layer.cornerRadius = 5
            button.layer.masksToBounds = true
            button.tag = i
            self.addSubview(button)
            let row = i / 3
            let column = i % 3
            button.snp.makeConstraints { make in
                make.top.equalTo(self).offset((row * (46 + 6)) + 6)
                make.left.equalTo(self).offset(((column % 3) * (itemWidth + 6)) + 6)
                make.size.equalTo(CGSize.init(width: itemWidth, height: 46))
            }
            button.addTarget(self, action: #selector(keyboardEvent(_:)), for: .touchUpInside)
        }
        self.addSubViews([self.deleteBtn])
        self.deleteBtn.addTarget(self, action: #selector(deleteBtnClick), for: .touchUpInside)
        self.deleteBtn.snp.makeConstraints { make in
            make.top.equalTo(self).offset((3 * (46 + 6)) + 6)
            make.left.equalTo(self).offset((2 * (itemWidth + 6)) + 6)
            make.size.equalTo(CGSize.init(width: itemWidth, height: 46))
        }
    }
    
    @objc func keyboardEvent(_ button: UIButton){
        if (self.value.count == 18){
            return
        }
        if button.tag == 9 {
            if (self.value.count != 17){
                return
            }
            self.value.append("X")
        }else if button.tag == 10 {
            self.value.append("0")
        }else{
            self.value.append("\(button.tag + 1)")
        }
        guard let block = self.valueBlock else {
            return
        }
        
        var isValid = false
        if self.value.count == 18{
            let calculateList: [Int] = [7, 9, 10, 5, 8, 4, 2, 1, 6, 3, 7, 9, 10, 5, 8, 4, 2, 0]
            let checkList:[String] = ["1","0","X","9","8","7","6","5","4","3","2",]
            var sum: Int = 0
            for (index, num) in self.value.enumerated() {
                sum = sum + (Int("\(num)") ?? 0) * calculateList[index]
            }
            let checkIndex = sum % 11
            isValid = checkList[checkIndex] == self.value.suffix(1)
        }
        block(self.value, isValid)
    }
    
    @objc func deleteBtnClick() {
        if self.value.count != 0 {
            self.value.removeLast()
        }
        guard let block = self.valueBlock else {
            return
        }
        block(self.value, false)
    }
}
