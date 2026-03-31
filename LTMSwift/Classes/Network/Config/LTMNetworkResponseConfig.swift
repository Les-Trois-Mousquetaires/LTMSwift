//
//  LTMNetworkResponseConfig.swift
//  LTMSwift
//

import Foundation

/// Response parsing behavior configuration.
public struct LTMNetworkResponseConfig {
    /// Response key for business status code. Example: `code`.
    public var codeKey: String

    /// Accepted business success code values.
    ///
    /// Any matched value is treated as success.
    public var successCodes: Set<String>

    /// Accepted HTTP status codes.
    public var successStatusCodes: Set<Int>

    /// Response key that contains business payload. Example: `data`.
    public var dataKey: String

    public init(
        codeKey: String = "code",
        successCodes: Set<String> = ["200"],
        successStatusCodes: Set<Int> = Set(200...299),
        dataKey: String = "data"
    ) {
        self.codeKey = codeKey
        self.successCodes = successCodes
        self.successStatusCodes = successStatusCodes
        self.dataKey = dataKey
    }
}
