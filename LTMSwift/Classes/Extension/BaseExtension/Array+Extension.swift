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
public extension Array {
    /// 数组转JSON字符串
    var jsonString: String? {
        return self.toJSONString()
    }

    /**
     数组转JSON字符串

     - parameter prettyPrinted 是否格式化输出
     - returns JSON字符串，转换失败返回nil
     */
    func toJSONString(prettyPrinted: Bool = false) -> String? {
        guard JSONSerialization.isValidJSONObject(self) else { return nil }
        let options: JSONSerialization.WritingOptions = prettyPrinted ? [.prettyPrinted] : []
        guard let data = try? JSONSerialization.data(withJSONObject: self, options: options) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }
}
