//
//  RichListView.swift
//  LTMSwift
//
//  Created by zsn on 2022/12/4.
//

import SnapKit

open class RichListView: UIView {
    public var eventBlock: ((_ eventKey: String, _ text: String, _ isOn: Bool) -> Void)?
    private var sectionData: [[RichModel]] = []
    private var grouped = false
    private var backgrounds: [UIView] = []
    private var customHeaders: [Int: UIView] = [:]
    private var measuredHeaderWidth: CGFloat = 0
    private var isUpdatingGroups = false

    // 原有单组入口；赋值后恢复单组显示。
    public var model: [RichModel] {
        get { sectionData.flatMap { $0 } }
        set {
            grouped = false
            sectionData = newValue.isEmpty ? [] : [newValue]
            reloadData()
        }
    }

    // 多分组入口；自动过滤空组。
    public var groups: [[RichModel]] {
        get { sectionData }
        set {
            grouped = true
            sectionData = newValue.filter { !$0.isEmpty }
            reloadData()
        }
    }
    // 标题按非空分组顺序对应，不包含在阴影背景中。
    // 自定义分组头优先于文字标题；同一个视图不可同时用于多个分组。
    public var groupHeaderProvider: ((Int) -> UIView?)? { didSet { reloadData() } }
    public var groupTitles: [String] = [] { didSet { if !isUpdatingGroups { reloadData() } } }
    public var groupTitleHeight: CGFloat = 40 { didSet { reloadData() } }
    // 旧 model 模式的列表圆角，分组模式不使用。
    public var radius: CGFloat = 0 { didSet { setNeedsLayout() } }
    // 分组背景圆角，默认 10 点，与阴影模糊半径独立。
    public var groupCornerRadius: CGFloat = 10 { didSet { setNeedsLayout() } }
    // 内部容器与列表边缘的留白，不是滚动内容 inset。
    public var contentInsets: UIEdgeInsets = .zero { didSet { updateConstraintsForContent() } }
    // 兼容旧调用，统一转发到 contentInsets。
    @available(*, deprecated, renamed: "contentInsets")
    public var edges: UIEdgeInsets {
        get { contentInsets }
        set { contentInsets = newValue }
    }
    public var groupSpacing: CGFloat = 14 { didSet { reloadData() } }
    public var groupBackgroundColor: UIColor = .white { didSet { updateBackgroundAppearance() } }
    public var groupShadowColor: UIColor = .black { didSet { updateBackgroundAppearance() } }
    public var groupShadowOpacity: Float = 0 { didSet { updateBackgroundAppearance() } }
    public var groupShadowRadius: CGFloat = 6 { didSet { updateBackgroundAppearance() } }
    public var groupShadowOffset: CGSize = CGSize(width: 0, height: 4) { didSet { updateBackgroundAppearance() } }

    // 默认保持嵌入式列表；开启后由列表承担整页滚动。
    public var isScrollEnabled: Bool = false {
        didSet {
            tableview.isScrollEnabled = isScrollEnabled
            clipsToBounds = isScrollEnabled
            updateConstraintsForContent()
        }
    }
    // 表头和表尾通过内部约束自动计算高度。
    public var headerView: UIView? { didSet { tableview.tableHeaderView = headerView; refreshAccessoryLayout() } }
    public var footerView: UIView? { didSet { tableview.tableFooterView = footerView; refreshAccessoryLayout() } }

    /**
     一次配置分组和标题，过滤空组时同步过滤对应标题。

     - parameters groups 原始分组行数据
     - parameters titles 与原始分组索引对应的标题，缺失时使用空标题
     */
    public func setGroups(_ groups: [[RichModel]], titles: [String] = []) {
        let indices = groups.indices.filter { !groups[$0].isEmpty }
        grouped = true
        sectionData = indices.map { groups[$0] }
        isUpdatingGroups = true
        groupTitles = indices.map { titles.indices.contains($0) ? titles[$0] : "" }
        isUpdatingGroups = false
        reloadData()
    }

    /**
     设置各分组背景的阴影，不给 TableView 或 Cell 添加阴影。

     - parameters color 阴影颜色
     - parameters opacity 阴影透明度
     - parameters radius 阴影模糊半径
     - parameters offset 阴影偏移
     */
    public func setGroupShadow(
        color: UIColor = .black,
        opacity: Float = 0.08,
        radius: CGFloat = 6,
        offset: CGSize = CGSize(width: 0, height: 4)
    ) {
        groupShadowColor = color
        groupShadowOpacity = opacity
        groupShadowRadius = radius
        groupShadowOffset = offset
    }

    /** 创建列表。 */
    public override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(bgView)
        bgView.addSubview(tableview)
        updateConstraintsForContent()
    }

    /** 不支持归档初始化。 */
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /** 更新分组背景和阴影路径。 */
    open override func layoutSubviews() {
        super.layoutSubviews()
        // 先完成容器约束布局，再测量列表宽度和转换行坐标。
        bgView.layoutIfNeeded()
        if measuredHeaderWidth != tableview.bounds.width {
            measuredHeaderWidth = tableview.bounds.width
            updateConstraintsForContent()
            bgView.layoutIfNeeded()
            if !customHeaders.isEmpty { tableview.reloadData() }
        }
        if updateAccessorySizes() {
            updateConstraintsForContent()
            bgView.layoutIfNeeded()
        }
        tableview.layoutIfNeeded()
        tableview.layer.cornerRadius = grouped ? 0 : radius
        updateGroupBackgroundFrames()
    }

    /** 更新分组背景，使其跟随滚动位置。 */
    private func updateGroupBackgroundFrames() {
        guard tableview.bounds.width > 0, tableview.bounds.height > 0 else { return }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        defer { CATransaction.commit() }
        for (section, background) in backgrounds.enumerated() {
            guard sectionData.indices.contains(section), section < tableview.numberOfSections,
                  tableview.numberOfRows(inSection: section) == sectionData[section].count else { continue }
            let first = tableview.rectForRow(at: IndexPath(row: 0, section: section))
            let last = tableview.rectForRow(at: IndexPath(row: sectionData[section].count - 1, section: section))
            background.frame = tableview.convert(first.union(last), to: bgView)
            let cornerRadius = max(groupCornerRadius, 0)
            background.layer.cornerRadius = cornerRadius
            background.layer.shadowPath = UIBezierPath(roundedRect: background.bounds, cornerRadius: cornerRadius).cgPath
        }
    }

    /** 更新背景样式，不重建列表或正在编辑的行。 */
    private func updateBackgroundAppearance() {
        for view in backgrounds {
            view.backgroundColor = groupBackgroundColor
            view.layer.shadowColor = groupShadowColor.cgColor
            view.layer.shadowOpacity = min(max(groupShadowOpacity, 0), 1)
            view.layer.shadowRadius = max(groupShadowRadius, 0)
            view.layer.shadowOffset = groupShadowOffset
        }
    }

    /** 刷新所有数据及列表高度。 */
    public func reloadData() {
        customHeaders.removeAll()
        if grouped {
            for section in sectionData.indices {
                if let header = groupHeaderProvider?(section) { customHeaders[section] = header }
            }
        }
        backgrounds.forEach { $0.removeFromSuperview() }
        backgrounds = grouped ? sectionData.map { _ in
            let view = UIView()
            view.isUserInteractionEnabled = false
            bgView.insertSubview(view, belowSubview: tableview)
            return view
        } : []
        updateBackgroundAppearance()
        updateConstraintsForContent()
        tableview.reloadData()
        setNeedsLayout()
    }

    /** 刷新指定行及布局。

     - parameters indexPaths 行索引，包含分组索引
     */
    public func reloadRowData(indexPaths: [IndexPath]) {
        guard indexPaths.allSatisfy({ sectionData.indices.contains($0.section)
            && sectionData[$0.section].indices.contains($0.row) }),
            tableview.numberOfSections == sectionData.count,
            sectionData.indices.allSatisfy({ tableview.numberOfRows(inSection: $0) == sectionData[$0].count }) else {
            reloadData()
            return
        }
        updateConstraintsForContent()
        let uniquePaths = Array(Set(indexPaths))
        guard !uniquePaths.isEmpty else { return }
        tableview.reloadRows(at: uniquePaths, with: .none)
        setNeedsLayout()
    }

    /** 更新容器和固定高度约束。 */
    private func updateConstraintsForContent() {
        bgView.snp.remakeConstraints { make in make.edges.equalTo(self).inset(contentInsets) }
        let titleHeight = sectionData.indices.reduce(CGFloat.zero) { $0 + titleHeightForSection($1) }
        let height = sectionData.flatMap { $0 }.reduce(CGFloat.zero) { $0 + $1.height }
            + CGFloat(max(sectionData.count - 1, 0)) * max(groupSpacing, 0) + titleHeight + (headerView?.frame.height ?? 0) + (footerView?.frame.height ?? 0)
        tableview.snp.remakeConstraints { make in
            make.edges.equalTo(bgView)
            if !isScrollEnabled { make.height.equalTo(height) }
        }
        setNeedsLayout()
    }

    /** 返回有效标题高度。

     - parameters section 分组索引
     */
    private func titleHeightForSection(_ section: Int) -> CGFloat {
        if let header = customHeaders[section] {
            let width = tableview.bounds.width
            guard width > 0 else { return 0 }
            return ceil(header.systemLayoutSizeFitting(
                CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
                withHorizontalFittingPriority: .required,
                verticalFittingPriority: .fittingSizeLevel
            ).height)
        }
        guard grouped, groupTitles.indices.contains(section), !groupTitles[section].isEmpty else { return 0 }
        return max(groupTitleHeight, 0)
    }

    /** 内容变化后重新计算表头、表尾和分组布局。 */
    public func refreshAccessoryLayout() {
        updateConstraintsForContent()
        tableview.reloadData()
        setNeedsLayout()
    }

    /** 根据实际宽度更新表头和表尾高度。 */
    private func updateAccessorySizes() -> Bool {
        guard tableview.bounds.width > 0 else { return false }
        var changed = false
        for accessory in [headerView, footerView].compactMap({ $0 }) {
            let size = accessory.systemLayoutSizeFitting(
                CGSize(width: tableview.bounds.width, height: UIView.layoutFittingCompressedSize.height),
                withHorizontalFittingPriority: .required,
                verticalFittingPriority: .fittingSizeLevel
            )
            let frame = CGRect(x: 0, y: 0, width: tableview.bounds.width, height: ceil(size.height))
            if accessory.frame != frame {
                changed = true
                accessory.frame = frame
                if accessory === headerView { tableview.tableHeaderView = accessory }
                if accessory === footerView { tableview.tableFooterView = accessory }
            }
        }
        return changed
    }

    /** 分组模式下由背景层承载颜色。

     - parameters cell 行视图
     */
    private func configureBackground(_ cell: UITableViewCell) {
        if grouped {
            cell.backgroundColor = .clear
            cell.contentView.backgroundColor = .clear
        }
    }

    private lazy var bgView: UIView = {
        let view = UIView()
        return view
    }()

    private lazy var tableview: UITableView = {
        let table = UITableView(frame: .zero, style: .grouped)
        table.delegate = self
        table.dataSource = self
        table.adapt()
        table.isScrollEnabled = false
        table.backgroundColor = .clear
        table.estimatedRowHeight = 0
        table.tableHeaderView = nil
        table.tableFooterView = nil
        return table
    }()
}

extension RichListView: UITableViewDelegate, UITableViewDataSource{
    /** 更新滚动中的分组背景。

     - parameters scrollView 列表滚动视图
     */
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateGroupBackgroundFrames()
    }

    /** 返回分组数量。

     - parameters tableView 列表
     */
    public func numberOfSections(in tableView: UITableView) -> Int { sectionData.count }

    /** 返回自定义分组头或文字标题的高度。

     - parameters tableView 列表
     - parameters section 分组索引
     */
    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        max(titleHeightForSection(section), .leastNormalMagnitude)
    }

    /** 创建随分组滚动的标题。

     - parameters tableView 列表
     - parameters section 分组索引
     */
    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if let header = customHeaders[section] { return header }
        let view = UIView()
        if titleHeightForSection(section) > 0 {
            let label = UILabel()
            label.text = groupTitles[section]
            label.textColor = .label
            label.font = .systemFont(ofSize: 14, weight: .semibold)
            view.addSubview(label)
            label.snp.makeConstraints { make in
                make.left.equalTo(view).offset(10)
                make.right.equalTo(view).offset(-10)
                make.centerY.equalTo(view)
            }
        }
        return view
    }

    /** 设置分组间距。

     - parameters tableView 列表
     - parameters section 分组索引
     */
    public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        section < sectionData.count - 1 ? max(groupSpacing, .leastNormalMagnitude) : .leastNormalMagnitude
    }

    /** 分组间使用透明视图。

     - parameters tableView 列表
     - parameters section 分组索引
     */
    public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? { UIView() }

    /** 配置行内容。

     - parameters tableView 列表
     - parameters indexPath 行索引
     */
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let data = self.sectionData[indexPath.section][indexPath.row]
        switch data.type {
        case .textfield:
            let cell: RichTextFieldTVCell = tableView.dequeueReusableCell(withIdentifier: "RichTextFieldTVCell") as? RichTextFieldTVCell ?? RichTextFieldTVCell.init(style: .default, reuseIdentifier: "RichTextFieldTVCell")
            cell.model = data
            cell.textFieldEvnentBlock = {[weak self] text in
                self?.clickEvent(data, text, false)
            }
            
            self.configureBackground(cell)
            return cell
        case .richLabel:
            let cell: RichLabelTVCell = tableView.dequeueReusableCell(withIdentifier: "RichLabelTVCell") as? RichLabelTVCell ?? RichLabelTVCell.init(style: .default, reuseIdentifier: "RichLabelTVCell")
            cell.model = data
            
            self.configureBackground(cell)
            return cell
        case .richLabelImage:
            let cell = tableView.dequeueReusableCell(withIdentifier: "RichLabelImageTVCell") as? RichLabelImageTVCell ?? RichLabelImageTVCell.init(style: .default, reuseIdentifier: "RichLabelImageTVCell")
            cell.model = data
            
            self.configureBackground(cell)
            return cell
        case .textSwitch:
            let cell = tableView.dequeueReusableCell(withIdentifier: "RichTextSwitchTVCell") as? RichTextSwitchTVCell ?? RichTextSwitchTVCell.init(style: .default, reuseIdentifier: "RichTextSwitchTVCell")
            cell.model = data
            cell.textSwitchBlock = {[weak self] isOn in
                self?.clickEvent(data, "", isOn)
            }
            self.configureBackground(cell)
            return cell
        }
    }
    
    /** 返回模型行高。

     - parameters tableView 列表
     - parameters indexPath 行索引
     */
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return self.sectionData[indexPath.section][indexPath.row].height
    }
    
    /** 返回分组行数。

     - parameters tableView 列表
     - parameters section 分组索引
     */
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.sectionData[section].count
    }
    
    /** 响应行点击。

     - parameters tableView 列表
     - parameters indexPath 行索引
     */
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let data = self.sectionData[indexPath.section][indexPath.row]
        switch data.type {
        case .textfield:
            break
        case .richLabel:
            self.clickEvent(data, "", false)
        case .richLabelImage:
            self.clickEvent(data, "", false)
        case .textSwitch:
            break
        }
        
    }
    
    /** 处理点击事件。

     - parameters data 行模型
     - parameters text 输入内容
     - parameters isOn 开关状态
     */
    private func clickEvent(_ data: RichModel, _ text: String, _ isOn: Bool){
        if data.eventKey.count > 0{
            guard let block = self.eventBlock else {
                return
            }
            block(data.eventKey, text, isOn)
        }
    }
}
