//
//  UITableView+Extension.swift
//  LTMSwift
//
//  Created by 柯南 on 2022/11/30.
//

import Foundation

public extension UITableView{
    // 列表适配
    func adapt(){
        self.separatorStyle = .none
        self.showsVerticalScrollIndicator = false
        self.showsHorizontalScrollIndicator = false
        self.tableHeaderView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: CGFloat.leastNormalMagnitude))
        self.estimatedSectionHeaderHeight = 0.0
        self.tableFooterView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: CGFloat.leastNormalMagnitude))
        self.estimatedSectionFooterHeight = 0.0
        self.estimatedRowHeight = 44
        self.rowHeight = UITableView.automaticDimension
        self.contentInsetAdjustmentBehavior = .never
        
        if #available(iOS 15.0, *) {
            self.sectionHeaderTopPadding = 0
        }
    }
}
