//
//  Dictionary+Extension.swift
//  LTMSwift
//
//  Created by Codex.
//

import Foundation

private enum LTMJSONHelper {
    /**
     递归清理对象中的 Optional(nil) 与 NSNull
     */
    static func clean(value: Any) -> Any? {
        if value is NSNull {
            return nil
        }

        let mirror = Mirror(reflecting: value)
        if mirror.displayStyle == .optional {
            guard let child = mirror.children.first else { return nil }
            return clean(value: child.value)
        }

        if let dictionary = value as? [String: Any] {
            return dictionary.removingNullValues()
        }

        if let array = value as? [Any] {
            return array.compactMap { clean(value: $0) }
        }

        return value
    }

    /**
     将合法 JSON 对象转字符串
     */
    static func jsonString(from object: Any, prettyPrinted: Bool) -> String? {
        guard JSONSerialization.isValidJSONObject(object) else { return nil }
        let options: JSONSerialization.WritingOptions = prettyPrinted ? [.prettyPrinted] : []
        guard let data = try? JSONSerialization.data(withJSONObject: object, options: options) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }
}

public extension Dictionary where Key == String {
    /**
     字典去空值（移除nil/NSNull，递归处理数组和字典）

     - returns 清理后的字典
     */
    func removingNullValues() -> [String: Any] {
        var result: [String: Any] = [:]
        for (key, value) in self {
            if let cleanValue = LTMJSONHelper.clean(value: value) {
                result[key] = cleanValue
            }
        }
        return result
    }

    /// 字典转JSON字符串
    var jsonString: String? {
        return self.toJSONString()
    }

    /**
     字典转JSON字符串

     - parameter prettyPrinted 是否格式化输出
     - returns JSON字符串，转换失败返回nil
     */
    func toJSONString(prettyPrinted: Bool = false) -> String? {
        return LTMJSONHelper.jsonString(from: self, prettyPrinted: prettyPrinted)
    }
}
