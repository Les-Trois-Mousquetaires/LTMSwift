//
//  TimePickerView.swift
//  LTMSwift
//
//  Created by 柯南 on 2022/12/28.
//  日期组件

import UIKit
import SnapKit

/// 日期展示格式
public enum TimePickerMode {
    /// 年
    case TimeModleY
    /// 年月
    case TimeModleYM
    /// 年月日
    case TimeModleYMD
    /// 年月日时
    case TimeModleYMDH
    /// 年月日时分
    case TimeModleYMDHM
    /// 年月日时分秒
    case TimeModleYMDHMS
}

open class TimePickerView: UIView {
    /// 时间回调
    public var dateBlock: ((_ date: Date) -> Void)?
    
    /// 最大时间
    private var curMaxDate: Date = Date()
    public var maxDate: Date{
        set{
            self.curMaxDate = newValue
        }get{
            self.curMaxDate
        }
    }
    /// 最小时间
    private var curMinDate: Date = Date()
    public var minDate: Date{
        set{
            self.curMinDate = newValue
        }get{
            self.curMinDate
        }
    }
    
    private var curDate: Date = Date()
    /// 当前时间
    public var defaultDate: Date {
        set{
            self.curDate = newValue
            self.configSelectRow(date: self.curDate, yearRow: 501, isScroll: true)
        }get{
            self.curDate
        }
    }
    
    /// 当前展示样式 默认 年月日
    public var mode: TimePickerMode = .TimeModleYMDHMS
    
    private var curLayerColor: UIColor = .brown
    /// 当前选中框颜色
    public var layerColor: UIColor {
        set{
            self.curLayerColor = newValue
            let path = UIBezierPath.init(roundedRect: CGRect(x: 10, y: UIScreen.main.bounds.size.width / 2 - 35 , width: UIScreen.main.bounds.size.width - 10 * 2, height: 70), cornerRadius: 5)
            let shapeLayer = CAShapeLayer()
            shapeLayer.path = path.cgPath
            shapeLayer.fillColor = UIColor.clear.cgColor
            shapeLayer.strokeColor = self.curLayerColor.cgColor
            shapeLayer.lineWidth = 2
            self.layer.addSublayer(shapeLayer)
        }get{
            self.curLayerColor
        }
    }
    
    private var curPickerColor: UIColor = .black
    /// 滚轮日期文本颜色
    public var pickerColor: UIColor {
        set{
            self.curPickerColor = newValue
        }get{
            self.curPickerColor
        }
    }
    
    private var curPickerFont: UIFont = .systemFont(ofSize: 16, weight: .medium)
    /// 滚轮日期文字字号
    public var pickerFont: UIFont {
        set{
            self.curPickerFont = newValue
        }get{
            self.curPickerFont
        }
    }
    
    /// 选择的年月日时分秒
    private var selectYear: Int = 0
    private var selectMonth: Int = 0
    private var selectDay: Int = 0
    private var selectHour: Int = 0
    private var selectMinute: Int = 0
    private var selectSecond: Int = 0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.configData()
        self.configUI()
        self.configSelectRow(date: self.defaultDate, yearRow: 501, isScroll: true)
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private lazy var timePickerView: UIPickerView = {
        let pickerView = UIPickerView()
        pickerView.delegate = self
        pickerView.dataSource = self
        pickerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        return pickerView
    }()
}

//MARK: - UIPickerViewDelegate
extension TimePickerView: UIPickerViewDelegate{
    public func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let label = UILabel()
        label.font = self.pickerFont
        label.textColor = self.pickerColor
        label.textAlignment = .center
        switch component{
        case 0:
            label.text = "\(self.defaultDate.year - 501 + row)年"
        case 1:
            label.text = "\(row % 12 + 1)月"
        case 2:
            label.text = "\(row % 31 + 1)日"
        case 3:
            label.text = "\(row % 24)时"
        case 4:
            label.text = "\(row % 60)分"
        case 5:
            label.text = "\(row % 60)秒"
        default:
            label.text = ""
        }
        
        return label
    }
    
    public func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 68
    }
    
    public func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        getWidthForComponent(component: component)
    }
    
    func getWidthForComponent(component: Int) -> CGFloat{
        switch self.mode{
        case .TimeModleY:
            return UIScreen.main.bounds.self.width
        case .TimeModleYM:
            return UIScreen.main.bounds.self.width / 3
        case .TimeModleYMD:
            return UIScreen.main.bounds.self.width / 5
        case .TimeModleYMDH:
            return UIScreen.main.bounds.self.width / 5
        default:
            if (component == 0){
                return UIScreen.main.bounds.self.width / 6
            }
            if (self.mode == .TimeModleYMDHMS){
                return UIScreen.main.bounds.self.width / 8
            }
            return UIScreen.main.bounds.self.width / 6
        }
    }
    
    public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if (component == 0) {
            self.selectYear = row - 501 + self.defaultDate.year;
        }
        if (component == 1) {
            self.selectMonth = row % 12 + 1;
        }
        if (component == 2) {
            self.selectDay = row % 31 + 1;
        }
        if (component == 3) {
            self.selectHour = row % 24;
        }
        if (component == 4) {
            self.selectMinute = row % 60;
        }
        if (component == 5) {
            self.selectSecond = row % 60;
        }
        checkDate(row: row)
        checkMaxDate(row: row)
        checkMinDate(row: row)
        guard let block = self.dateBlock else {
            return
        }
        
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = self.selectYear
        components.month = self.selectMonth
        components.day = self.selectDay
        components.hour = self.selectHour
        components.minute = self.selectMinute
        components.second = self.selectSecond
        block(calendar.date(from: components) ?? Date())
    }
    
    /**
     配置选中行
     
     - parameter date 时间
     - parameter yearRow 年索引位置
     - parameter isScroll 是否需要滚动
     */
    func configSelectRow(date: Date, yearRow: Int, isScroll: Bool){
        self.selectYear = date.year
        self.selectMonth = date.month
        self.selectDay = date.day
        self.selectHour = date.hour
        self.selectMinute = date.minute
        self.selectSecond = date.second
        
        switch self.mode{
        case .TimeModleY:
            self.timePickerView.selectRow(yearRow, inComponent: 0, animated: true)
        case .TimeModleYM:
            self.timePickerView.selectRow(yearRow, inComponent: 0, animated: true)
            self.timePickerView.selectRow(12 * 500 + date.month - 1, inComponent: 1, animated: true)
        case .TimeModleYMD:
            self.timePickerView.selectRow(yearRow, inComponent: 0, animated: true)
            self.timePickerView.selectRow(12 * 500 + date.month - 1, inComponent: 1, animated: true)
            self.timePickerView.selectRow(31 * 500 + date.day - 1, inComponent: 2, animated: true)
        case .TimeModleYMDH:
            self.timePickerView.selectRow(yearRow, inComponent: 0, animated: true)
            self.timePickerView.selectRow(12 * 500 + date.month - 1, inComponent: 1, animated: true)
            self.timePickerView.selectRow(31 * 500 + date.day - 1, inComponent: 2, animated: true)
            if (isScroll){
                self.timePickerView.selectRow(24 * 500 + date.hour, inComponent: 3, animated: true)
            }
        case .TimeModleYMDHM:
            self.timePickerView.selectRow(yearRow, inComponent: 0, animated: true)
            self.timePickerView.selectRow(12 * 500 + date.month - 1, inComponent: 1, animated: true)
            self.timePickerView.selectRow(31 * 500 + date.day - 1, inComponent: 2, animated: true)
            if (isScroll){
                self.timePickerView.selectRow(24 * 500 + date.hour, inComponent: 3, animated: true)
                self.timePickerView.selectRow(60 * 500 + date.minute, inComponent: 4, animated: true)
            }
        case .TimeModleYMDHMS:
            self.timePickerView.selectRow(yearRow, inComponent: 0, animated: true)
            self.timePickerView.selectRow(12 * 500 + date.month - 1, inComponent: 1, animated: true)
            self.timePickerView.selectRow(31 * 500 + date.day - 1, inComponent: 2, animated: true)
            if (isScroll){
                self.timePickerView.selectRow(24 * 500 + date.hour, inComponent: 3, animated: true)
                self.timePickerView.selectRow(60 * 500 + date.minute, inComponent: 4, animated: true)
                self.timePickerView.selectRow(60 * 500 + date.second, inComponent: 5, animated: true)
            }
        }
    }
    
    func checkDate(row: Int){
        var isReturn = false
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = self.selectYear
        components.month = self.selectMonth
        let days = calendar.date(from: components)!.days
        if (self.selectDay > days){
            self.selectDay = days
            isReturn = true
        }
        components.day = self.selectDay
        components.hour = self.selectHour
        components.minute = self.selectMinute
        components.second = self.selectSecond
        let selectDate = calendar.date(from: components)!
        if(isReturn){
            configSelectRow(date: selectDate, yearRow: row - (self.selectYear - self.maxDate.year), isScroll: false)
            return
        }
    }
    
    func checkMaxDate(row: Int){
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = self.selectYear
        components.month = self.selectMonth
        components.day = self.selectDay
        let selectDate = calendar.date(from: components)!
        if(selectDate.compare(self.maxDate) == .orderedDescending){
            configSelectRow(date: self.maxDate, yearRow: row - (self.selectYear - self.maxDate.year), isScroll: true)
        }
    }
    
    func checkMinDate(row: Int){
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = self.selectYear
        components.month = self.selectMonth
        components.day = self.selectDay
        let selectDate = calendar.date(from: components)!
        if(self.minDate.compare(selectDate) == .orderedDescending){
            configSelectRow(date: self.minDate, yearRow: row + (self.minDate.year - self.selectYear), isScroll: true)
        }
    }
}

//MARK: - UIPickerViewDataSource
extension TimePickerView: UIPickerViewDataSource{
    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        switch self.mode{
        case .TimeModleY:
            return 1
        case .TimeModleYM:
            return 2
        case .TimeModleYMD:
            return 3
        case .TimeModleYMDH:
            return 4
        case .TimeModleYMDHM:
            return 5
        case .TimeModleYMDHMS:
            return 6
        }
    }
    
    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch component{
        case 0:
            return 1000
        case 1:
            return 12 * 1000
        case 2:
            return 31 * 1000
        case 3:
            return 24 * 1000
        case 4:
            return 60 * 1000
        case 5:
            return 60 * 1000
        default:
            return 0
        }
    }
}

extension TimePickerView{
    func configData(){
        self.defaultDate = Date()
        self.pickerFont = .systemFont(ofSize: 16, weight: .medium)
        self.pickerColor = .black
        self.mode = .TimeModleYMDHMS
    }
    
    func configUI(){
        self.addSubview(self.timePickerView)
        self.timePickerView.snp.makeConstraints { make in
            make.edges.equalTo(self)
            make.height.equalTo(UIScreen.main.bounds.size.width)
        }
    }
}
