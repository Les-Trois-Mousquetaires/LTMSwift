//
//  String+Encryption.swift
//  LTMSwift
//
//  Created by 柯南 on 2022/11/29.
//

import CommonCrypto

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
}

public extension String{
    /// 字符串MD5
    var md5: String{
        return self.stringToMD5(outputFormat: "x")
    }
    
    /// 字符串哈希
    var sha1: String{
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

