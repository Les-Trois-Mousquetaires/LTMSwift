//
//  Sequence+Extension.swift
//  LTMSwift
//
//  Created by coenen on 2026/10/12.
//

import Foundation

public extension Sequence where Element == (String, Any?) {
    /** 将键值对转为字典，忽略 nil，同名键以最后一个非 nil 值为准。 */
    func toCompactDictionary() -> [String: Any] {
        reduce(into: [:]) { result, element in
            if let value = element.1 { result[element.0] = value }
        }
    }
}
