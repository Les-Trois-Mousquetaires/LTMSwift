//
//  String+Encryption.swift
//  LTMSwift
//
//  Created by 柯南 on 2022/11/29.
//

import CommonCrypto
import CryptoKit

public extension String {
    /// 字符串MD5
    var md5: String{
        guard let data = self.data(using: .utf8) else {
            return ""
        }
        return Self.md5(data: data)
    }
    
    /// 字符串哈希
    var sha1: String{
        guard let data = self.data(using: .utf8) else {
            return ""
        }
        return Self.sha1(data: data)
    }
    
    /// 字符串SHA256
    var sha256: String{
        guard let data = self.data(using: .utf8) else {
            return ""
        }
        return Self.sha256(data: data)
    }
    
    /// 文件路径MD5
    var fileMD5: String? {
        return Self.md5(fileAtPath: self)
    }
    
    /// 文件路径SHA1
    var fileSHA1: String? {
        return Self.sha1(fileAtPath: self)
    }
    
    /// 文件路径SHA256
    var fileSHA256: String? {
        return Self.sha256(fileAtPath: self)
    }
}

public extension String {
    /**
     字符串 DES加密
     
     - parameter key 密钥
     - parameter iv 偏移量
     - parameter options 加密方式
     */
    func desEncrypt(key:String, iv:String, options:Int = kCCOptionPKCS7Padding) -> String? {
        if let keyData = key.data(using: String.Encoding.utf8),
           let data = self.data(using: String.Encoding.utf8),
           let cryptData    = NSMutableData(length: Int((data.count)) + kCCBlockSizeDES) {
            let keyLength              = size_t(kCCKeySizeDES)
            let operation: CCOperation = UInt32(kCCEncrypt)
            let algoritm:  CCAlgorithm = UInt32(kCCAlgorithmDES)
            let options:   CCOptions   = UInt32(options)
            var numBytesEncrypted :size_t = 0
            let cryptStatus = CCCrypt(operation,
                                      algoritm,
                                      options,
                                      (keyData as NSData).bytes,
                                      keyLength,
                                      iv,
                                      (data as NSData).bytes,
                                      data.count,
                                      cryptData.mutableBytes,
                                      cryptData.length,
                                      &numBytesEncrypted)
            if UInt32(cryptStatus) == UInt32(kCCSuccess) {
                cryptData.length = Int(numBytesEncrypted)
                let base64cryptString = cryptData.base64EncodedString(options: .lineLength64Characters)
                return base64cryptString
            }
            else {
                return nil
            }
        }
        return nil
    }
    
    /**
     字符串 DES解密
     
     - parameter key 密钥
     - parameter iv 偏移量
     - parameter options 解密方式
     */
    func desDecrypt(key:String, iv:String, options:Int = kCCOptionPKCS7Padding) -> String? {
        if let keyData = key.data(using: String.Encoding.utf8),
           let data = NSData(base64Encoded: self, options: .ignoreUnknownCharacters),
           let cryptData    = NSMutableData(length: Int((data.length)) + kCCBlockSizeDES) {
            let keyLength              = size_t(kCCKeySizeDES)
            let operation: CCOperation = UInt32(kCCDecrypt)
            let algoritm:  CCAlgorithm = UInt32(kCCAlgorithmDES)
            let options:   CCOptions   = UInt32(options)
            var numBytesEncrypted :size_t = 0
            let cryptStatus = CCCrypt(operation,
                                      algoritm,
                                      options,
                                      (keyData as NSData).bytes, keyLength,
                                      iv,
                                      data.bytes, data.length,
                                      cryptData.mutableBytes, cryptData.length,
                                      &numBytesEncrypted)
            
            if UInt32(cryptStatus) == UInt32(kCCSuccess) {
                cryptData.length = Int(numBytesEncrypted)
                let unencryptedMessage = String(data: cryptData as Data, encoding:String.Encoding.utf8)
                return unencryptedMessage
            }
            else {
                return nil
            }
        }
        return nil
    }
    
    /**
     字符串 AES CBC加密
     
     - parameter key 密钥
     - parameter iv 偏移量
     */
    func aesEncrypt(key:String, iv:String, options:Int = kCCOptionPKCS7Padding) -> String? {
        if let keyData = key.data(using: String.Encoding.utf8),
           let data = self.data(using: String.Encoding.utf8),
           let cryptData    = NSMutableData(length: Int((data.count)) + kCCBlockSizeAES128) {
            let keyLength              = size_t(kCCKeySizeAES256)
            let operation: CCOperation = UInt32(kCCEncrypt)
            let algoritm:  CCAlgorithm = UInt32(kCCAlgorithmAES)
            let options:   CCOptions   = UInt32(options)
            var numBytesEncrypted :size_t = 0
            let cryptStatus = CCCrypt(operation,
                                      algoritm,
                                      options,
                                      (keyData as NSData).bytes,
                                      keyLength,
                                      iv,
                                      (data as NSData).bytes,
                                      data.count,
                                      cryptData.mutableBytes,
                                      cryptData.length,
                                      &numBytesEncrypted)
            if UInt32(cryptStatus) == UInt32(kCCSuccess) {
                cryptData.length = Int(numBytesEncrypted)
                let base64cryptString = cryptData.base64EncodedString(options: .lineLength64Characters)
                return base64cryptString
            }
            else {
                return nil
            }
        }
        return nil
    }
    
    /// Data转MD5
    static func md5(data: Data, uppercased: Bool = false) -> String {
        let digest = Insecure.MD5.hash(data: data)
        return Self.hexString(from: digest, uppercased: uppercased)
    }
    
    /// Data转SHA1
    static func sha1(data: Data, uppercased: Bool = false) -> String {
        let digest = Insecure.SHA1.hash(data: data)
        return Self.hexString(from: digest, uppercased: uppercased)
    }
    
    /// Data转SHA256
    static func sha256(data: Data, uppercased: Bool = false) -> String {
        let digest = SHA256.hash(data: data)
        return Self.hexString(from: digest, uppercased: uppercased)
    }
    
    /// 文件路径转MD5
    static func md5(fileAtPath path: String, uppercased: Bool = false) -> String? {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
            return nil
        }
        return Self.md5(data: data, uppercased: uppercased)
    }
    
    /// 文件路径转SHA1
    static func sha1(fileAtPath path: String, uppercased: Bool = false) -> String? {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
            return nil
        }
        return Self.sha1(data: data, uppercased: uppercased)
    }
    
    /// 文件路径转SHA256
    static func sha256(fileAtPath path: String, uppercased: Bool = false) -> String? {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
            return nil
        }
        return Self.sha256(data: data, uppercased: uppercased)
    }
    
    private static func hexString(from bytes: some Sequence<UInt8>, uppercased: Bool) -> String {
        return bytes.map { byte in
            let value = String(format: "%02x", byte)
            return uppercased ? value.uppercased() : value
        }.joined()
    }
}
