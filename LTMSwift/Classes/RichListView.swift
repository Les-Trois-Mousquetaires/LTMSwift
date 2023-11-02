//
//  RichListView.swift
//  LTMSwift
//
//  Created by zsn on 2022/12/4.
//

import SnapKit

open class RichListView: UIView{
    /// 响应Block
    public var eventBlock: ((_ eventKey: String) -> Void)?
    /// textField 响应Block
    public var textFieldEventBlock: ((_ eventKey: String, _ content: String) -> Void)?

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
        table.separatorStyle = .none
        
        return table
    }()
}

extension RichListView: UITableViewDelegate, UITableViewDataSource{
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "RichTVCell") as? RichTVCell
        if cell == nil{
            cell = RichTVCell.init(style: .default, reuseIdentifier: "RichTVCell")
        }
        let model = self.listData[indexPath.row]
        cell?.model = model
        cell?.eventBlock = {[weak self] in
            self?.clickEvent(model)
        }
        cell?.textFieldEvnentBlock = {[weak self] text in
            self?.textFieldEvent(model, text)
        }
        return cell!
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return self.listData[indexPath.row].height
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.listData.count
    }
    
    /// 处理点击事件
    private func clickEvent(_ model: RichModel){
        self.tableview.endEditing(true)
        if model.eventKey.count > 0{
            guard let block = self.eventBlock else {
                return
            }
            block(model.eventKey)
        }
    }
    
    /// textField 响应事件
    private func textFieldEvent(_ model: RichModel, _ text: String){
        guard let block = self.textFieldEventBlock else {
            return
        }
        block(model.eventKey, text)
    }
}
