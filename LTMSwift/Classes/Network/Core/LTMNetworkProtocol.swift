//
//  LTMNetworkProtocol.swift
//  LTMSwift
//
//  Created by zsn on 2022/12/4.
//

import SmartCodable

/// Model constraint used by the network layer.
/// Keep it as a typealias so business models can still declare `: LTMModel`.
public typealias LTMModel = SmartDecodable & SmartEncodable
