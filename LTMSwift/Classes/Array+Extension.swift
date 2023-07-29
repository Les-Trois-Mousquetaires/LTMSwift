//
//  Array+Extension.swift
//  LTMSwift
//
//  Created by zsn on 2023/7/29.
//

import Foundation

public extension Array where Element: Equatable {
    
    /// 去除数组重复元素
    var removeDuplicate: Array {
        return self.enumerated().filter { (index,value) -> Bool in
            return self.firstIndex(of: value) == index
        }.map { (_, value) in
            value
        }
    }
}
