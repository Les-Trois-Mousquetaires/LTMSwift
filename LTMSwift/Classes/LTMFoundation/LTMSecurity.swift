//
//  LTMSecurity.swift
//  Pods
//
//  Created by 柯南 on 2020/8/3.
//

import Foundation
import CommonCrypto

public extension String{
    /**
     字符串大写MD5
     
     - returns: MD5值
     */
    func strngToCapitalMD5() -> String{
        return self.stringToMD5(outputFormat: "X")
    }
    
    /**
     字符串小写MD5
     
     - returns: MD5值
     */
    func strngToLowercaseMD5() -> String{
        return self.stringToMD5(outputFormat: "x")
    }
    
    /**
     字符串大写SHA1
     
     - returns: 哈希值
     */
    func strngToCapitalSHA1() -> String {
        return self.stringToSHA1(outputFormat: "X")
    }
    
    /**
     字符串小写SHA1
     
     - returns: 哈希值
     */
    func strngToLowercaseSHA1() -> String {
        return self.stringToSHA1(outputFormat: "x")
    }
    
    private func stringToMD5(outputFormat: String) ->String{
        let string = self.cString(using: .utf8)
        let stringLength = CUnsignedInt(self.lengthOfBytes(using: String.Encoding.utf8))
        let digestLength = Int(CC_MD5_DIGEST_LENGTH)
        let result = UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: digestLength)
        CC_MD5(string, stringLength, result)
        let hash = NSMutableString()
        for i in 0 ..< digestLength{
            hash.appendFormat("%02\(outputFormat)" as NSString, result[i])
        }
        free(result)
        
        return hash as String
    }
    
    private func stringToSHA1(outputFormat: String) ->String{
        let data = self.data(using: String.Encoding.utf8)!
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
        CC_SHA1([UInt8](data), CC_LONG(data.count), &digest)
        let output = NSMutableString(capacity: Int(CC_SHA1_DIGEST_LENGTH))
        for byte in digest {
            output.appendFormat("%02\(outputFormat)" as NSString, byte)
        }
        
        return output as String
    }
    
}

