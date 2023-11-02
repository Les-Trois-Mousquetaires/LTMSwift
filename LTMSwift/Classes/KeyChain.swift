//
//  KeyChain.swift
//  Pods
//
//  Created by zsn on 2023/11/2.
//  钥匙串存储

import Foundation

public extension UIDevice {
    /// 获取设备唯一码
    func uniqueUUID(_ key: String) -> String {
        guard let result = KeyChain.getData(key: key) as? String else {
            guard let uuid = self.identifierForVendor?.uuidString else {
                return ""
            }
            
            let _ = KeyChain.save(key: key, data: uuid)
            
            return uuid
        }
        
        return result
    }
}

open class KeyChain: NSObject {
    //MARK: - 创建查询条件
    private class func getQuery(key: String) -> NSMutableDictionary {
        // 创建一个条件字典
        let param = NSMutableDictionary.init(capacity: 0)
        // 设置条件存储的类型
        param.setValue(kSecClassGenericPassword, forKey: "\(kSecClass)")
        // 设置存储数据的标记
        param.setValue(key, forKey: "\(kSecAttrService)")
        param.setValue(key, forKey: "\(kSecAttrAccount)")
        // 设置数据访问属性 只有设备解锁时才可以访问数据，该数据不可转移到新的设备使用
        param.setValue(kSecAttrAccessibleAfterFirstUnlock, forKey: "\(kSecAttrAccessible)")
        // 返回创建条件字典
        return param
    }
    
    //MARK: - 存储数据
    public class func save(key: String, data: Any) -> Bool {
        let query = self.getQuery(key: key)
        let _ = self.keyChianDelete(key: key)
        do {
            let saveData = try NSKeyedArchiver.archivedData(withRootObject: data, requiringSecureCoding: true)
            query.setValue(saveData, forKey: "\(kSecValueData)")
        } catch  {
            return false
        }
        let saveStatus = SecItemAdd(query, nil)
        if saveStatus == noErr  {
            return true
        }
        return false
    }
    
    //MARK: - 更新数据
    public class func update(key: String, data: Any) -> Bool {
        let param = KeyChain.getQuery(key: key)
        let updataParam = NSMutableDictionary.init(capacity: 0)
        do {
            // 设置数据
            let value = try NSKeyedArchiver.archivedData(withRootObject: data, requiringSecureCoding: true)
            updataParam.setValue(value, forKey: "\(kSecValueData)")
        } catch  {
            return false
        }
        // 更新数据
        let updataStatus = SecItemUpdate(param, updataParam)
        if updataStatus == noErr {
            return true
        }
        return false
    }
    
    public class func getData (key: String) -> Any? {
        var result:Any?
        // 获取查询条件
        let param = KeyChain.getQuery(key: key)
        // 提供查询数据的两个必要参数
        param.setValue(kCFBooleanTrue, forKey: "\(kSecReturnData)")
        param.setValue(kSecMatchLimitOne, forKey: "\(kSecMatchLimit)")
        // 创建获取数据的引用
        var queryResult: AnyObject?
        // 通过查询是否存储在数据
        let readStatus = withUnsafeMutablePointer(to: &queryResult) { SecItemCopyMatching(param, UnsafeMutablePointer($0))}
        if readStatus == errSecSuccess {
            
            guard let data = queryResult as? Data else {
                return result
            }
            
            do {
                result = try NSKeyedUnarchiver.unarchivedObject(ofClass: NSString.self, from: data)
            } catch  {
                
            }
        }
        return result
    }
    
    //MARK: - 删除数据
    public class func keyChianDelete(key:String) -> Bool{
        let param = KeyChain.getQuery(key: key)
        let status = SecItemDelete(param)
        
        return status == noErr
    }
}
