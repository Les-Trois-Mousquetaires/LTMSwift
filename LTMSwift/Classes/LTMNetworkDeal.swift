//
//  LTMNetworkDeal.swift
//  LTMSwift
//
//  Created by zsn on 2022/12/4.
//

import Foundation
import Moya

open class LTMNetworkDeal: NSObject {
    
    public var codeKey: String = "code"
    public var codeSuccess: String = "200"
    public var dataKey: String = "data"
    
    public func handleData<T: LTMModel>(model: T, response:Result<Response, MoyaError>, successBlock:((_ result: T?) -> Void)?, failureBlcok: ((_ result: Any?) -> Void)?) {
        switch response {
        case .success(let success):
            guard let data: [String: Any] = try? success.mapJSON() as? [String: Any] else {
                return
            }
            switch success.statusCode {
            case 200:
                let code = "\(data[self.codeKey] ?? "")"
                switch code {
                case self.codeSuccess:
                    guard let result: [String: Any] = data[self.dataKey] as? [String: Any] else {
                        successBlock?(successHandle(data: data, model: model))
                        return
                    }
                    successBlock?(successHandle(data: result, model: model))
                default:
                    failureBlcok?(failureHandle(data: data))
                }
            default:
                failureBlcok?(failureHandle(data: data))
            }
        case .failure(let failure):
            failureBlcok?(failureHandle(data: failure))
        }
    }
    
    private func successHandle<T: LTMModel>(data: [String: Any], model: T) -> T? {
        
        print("当前~~result~~successHandle", data, model)
        return T.deserialize(from: data)
    }
    
    open func failureHandle(data: Any) -> Any? {
        
        return data
    }
}
