//
//  Array+Extension.swift
//  LTMSwift
//
//  Created by zsn on 2023/7/29.
//

import Foundation

public extension Array where Element: Hashable {
    /// 数组去重
    var unique: Self {
        var list: Set<Element> = []
        
        return filter{
            list.insert($0).inserted
        }
    }
}
