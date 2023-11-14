//
//  RichListView.swift
//  LTMSwift
//
//  Created by zsn on 2022/12/4.
//

import SnapKit

open class RichListView: UIView{
    /**
     响应Block
     
     eventKey 响应Key
     text 输入框内容
     isOn 开关状态
     */
    public var eventBlock: ((_ eventKey: String, _ text: String, _ isOn: Bool) -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(self.tableview)
        self.tableview.snp.makeConstraints { make in
            make.edges.equalTo(self).inset(self.edgeInset)
        }
    }
    
    private var listData: [RichModel] = []
    /// 展示模型
    public var model: [RichModel] {
        set{
            self.listData = newValue
            var tableHeight = 0.0
            for item in self.listData{
                tableHeight += item.height
            }
            self.tableview.snp.remakeConstraints { make in
                make.edges.equalTo(self).inset(self.edgeInset)
                make.height.equalTo(tableHeight)
            }
            self.tableview.reloadData()
        }get{
            self.listData
        }
    }
    
    /// 拐角半径
    public var radius: CGFloat {
        set{
            self.tableview.layer.cornerRadius = newValue
        }get{
            0
        }
    }
    
    private var edgeInset: UIEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    /// 列表与视图间距
    public var edges: UIEdgeInsets {
        set{
            self.edgeInset = newValue
        }get{
            self.edgeInset
        }
    }
    /// 刷新所有数据
    public func reloadData(){
        self.tableview.reloadData()
    }
    
    /// 刷新Rows数据
    public func reloadRowData(indexPaths: [IndexPath]){
        self.tableview.reloadRows(at: indexPaths, with: .none)
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private lazy var tableview: UITableView = {
        let table = UITableView.init(frame: CGRect.zero, style: .plain)
        table.delegate = self
        table.dataSource = self
        table.adapt()
        table.isScrollEnabled = false
        table.backgroundColor = .clear
        
        return table
    }()
}

extension RichListView: UITableViewDelegate, UITableViewDataSource{
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let data = self.listData[indexPath.row]
        switch data.type {
        case .textfield:
            var cell: RichTextFieldTVCell = tableView.dequeueReusableCell(withIdentifier: "RichTextFieldTVCell") as? RichTextFieldTVCell ?? RichTextFieldTVCell.init(style: .default, reuseIdentifier: "RichTextFieldTVCell")
            cell.model = data
            cell.textFieldEvnentBlock = {[weak self] text in
                self?.clickEvent(data, text, false)
            }
            
            return cell
        case .richLabel:
            var cell: RichLabelTVCell = tableView.dequeueReusableCell(withIdentifier: "RichLabelTVCell") as? RichLabelTVCell ?? RichLabelTVCell.init(style: .default, reuseIdentifier: "RichLabelTVCell")
            cell.model = data
            cell.eventBlock = {[weak self] in
                self?.clickEvent(data, "", false)
            }
            
            return cell
        case .richLabelImage:
            var cell = tableView.dequeueReusableCell(withIdentifier: "RichLabelImageTVCell") as? RichLabelImageTVCell ?? RichLabelImageTVCell.init(style: .default, reuseIdentifier: "RichLabelImageTVCell")
            cell.model = data
            cell.eventBlock = {[weak self] in
                self?.clickEvent(data, "", false)
            }
            
            return cell
        case .textSwitch:
            var cell = tableView.dequeueReusableCell(withIdentifier: "RichTextSwitchTVCell") as? RichTextSwitchTVCell ?? RichTextSwitchTVCell.init(style: .default, reuseIdentifier: "RichTextSwitchTVCell")
            cell.model = data
            cell.textSwitchBlock = {[weak self] isOn in
                self?.clickEvent(data, "", isOn)
            }
            return cell
        }
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return self.listData[indexPath.row].height
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.listData.count
    }
    
    /// 处理点击事件
    private func clickEvent(_ data: RichModel, _ text: String, _ isOn: Bool){
        self.tableview.endEditing(true)
        if data.eventKey.count > 0{
            guard let block = self.eventBlock else {
                return
            }
            block(data.eventKey, text, isOn)
        }
    }
}
