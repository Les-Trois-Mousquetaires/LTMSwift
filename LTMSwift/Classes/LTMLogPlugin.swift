//
//  LTMLogPlugin.swift
//  FBSnapshotTestCase
//
//  Created by zsn on 2022/12/4.
//  请求Log输出

import Moya

open class LTMLogPlugin: PluginType{
    public init() {
    }

    open func willSend(_ request: RequestType, target: TargetType) {
        print("请求头 \(request.request?.allHTTPHeaderFields ?? [:])")
        if request.request?.method == .post{
            do {
                let dic = try JSONSerialization.jsonObject(with: request.request?.httpBody ?? Data(), options: .mutableContainers) as AnyObject
                print("请求参数 \(dic)")
            } catch  {
                print("请求参数 \(error)")
            }
        }
    }
    
    open func didReceive(_ result: Result<Response, MoyaError>, target: TargetType) {
        switch result {
        case .success(let response):
            guard let resultDic: [String: Any] = try? response.mapJSON() as? [String : Any] else {
                return
            }
            print("请求地址\n\((response.request?.url?.absoluteString ?? ""))\n返回数据\n\(resultDic)")
        case .failure(let error):
            print("end failure")
            print(error)
        }
    }
}
