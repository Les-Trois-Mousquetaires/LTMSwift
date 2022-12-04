//
//  LTMNetworkDeal.swift
//  FBSnapshotTestCase
//
//  Created by zsn on 2022/12/4.
//

import Foundation
import Moya

open class LTMNetworkDeal: NSObject {
    /// 数据成功返回码 与dataValue、msgValue 同一级
    public var codeValue: String = "code"
    /// 有效数据返回字段 与codeValue、msgValue 同一级
    public var dataValue: String = "entity"
    /// 错误信息返回字段， 与codeValue、dataValue 同一级
    public var msgValue: String = "message"
    
    //MARK: - 数据处理中心
    public func dealWithResult<Model: LTMModel>(targetName: Model,result: Result<Response, MoyaError>, successClosure:((_ result: Any) -> ())? = nil, failureClosure:((_ errorCode: Int, _ errorMessage: String) ->())? = nil){
        
        switch result {
        case let .success(moyaResponse):
            switch moyaResponse.statusCode {
            case 200:
                guard let resultDic: [String: Any] = try? moyaResponse.mapJSON() as? [String : Any],
                      let code: Int = resultDic[codeValue] as? Int
                else {
                    DispatchQueue.main.async {
                        failureClosure?(200, "数据解析异常")
                    }
                    return
                }
                
                switch code {
                case 200:
                    guard let systemEntity: [String: Any] = resultDic[dataValue] as? [String : Any] else {
                        DispatchQueue.main.async {
                            successClosure?(self.successDealWtih(response: resultDic, targetName: targetName ))
                        }
                        return
                    }
                    DispatchQueue.main.async {
                        successClosure?(self.successDealWtih(response: systemEntity, targetName: targetName ))
                    }
                    
                default:
                    if resultDic[msgValue] != nil{
                        DispatchQueue.main.async {
                            failureClosure?(code, self.failureDealWith(response: resultDic) ?? "服务器异常,未确认错误信息")
                        }
                    }
                }
            default:
                DispatchQueue.main.async {
                    failureClosure?(moyaResponse.statusCode, self.failureDealWith(response: "errorServerMes") ?? "服务器异常")
                }
            }
        case let .failure(error):
            print("error \(error)")
            DispatchQueue.main.async {
                failureClosure?(error.errorCode, error.errorDescription ?? "网络请求异常,请稍后重试!")
            }
        }
    }
    
    //MARK: - Deal info
    private func successDealWtih<Model: LTMModel>(response: [String : Any], targetName: Model) -> Any{
        let resultModel = Model.deserialize(from: response)
        
        return resultModel ?? NSObject()
    }
    
    open func failureDealWith(response: Any) -> String?{
        return "failure"
    }
}
