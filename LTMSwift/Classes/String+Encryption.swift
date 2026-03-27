//
//  String+Encryption.swift
//  LTMSwift
//
//  Created by 柯南 on 2022/11/29.
//

import CommonCrypto
import CryptoKit

public extension String {
    /// Base64编码（UTF-8）
    var base64Encoded: String? {
        guard let data = self.data(using: .utf8) else { return nil }
        return data.base64EncodedString()
    }

    /// Base64解码（UTF-8，失败返回nil）
    var base64Decoded: String? {
        guard let data = Data(base64Encoded: self, options: .ignoreUnknownCharacters) else { return nil }
        return String(data: data, encoding: .utf8)
    }

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
        guard let keyData = Self.validatedData(from: key, lengths: [kCCKeySizeDES]),
              let ivData = Self.validatedData(from: iv, lengths: [kCCBlockSizeDES]),
              let data = self.data(using: .utf8) else {
            return nil
        }
        return Self.crypt(input: data, operation: CCOperation(kCCEncrypt), algorithm: CCAlgorithm(kCCAlgorithmDES), options: CCOptions(options), key: keyData, iv: ivData)?.base64EncodedString(options: .lineLength64Characters)
    }
    
    /**
     字符串 DES解密
     
     - parameter key 密钥
     - parameter iv 偏移量
     - parameter options 解密方式
     */
    func desDecrypt(key:String, iv:String, options:Int = kCCOptionPKCS7Padding) -> String? {
        guard let keyData = Self.validatedData(from: key, lengths: [kCCKeySizeDES]),
              let ivData = Self.validatedData(from: iv, lengths: [kCCBlockSizeDES]),
              let data = Data(base64Encoded: self, options: .ignoreUnknownCharacters),
              let decryptedData = Self.crypt(input: data, operation: CCOperation(kCCDecrypt), algorithm: CCAlgorithm(kCCAlgorithmDES), options: CCOptions(options), key: keyData, iv: ivData) else {
            return nil
        }
        return String(data: decryptedData, encoding: .utf8)
    }
    
    /**
     字符串 AES CBC加密
     
     - parameter key 密钥
     - parameter iv 偏移量
     */
    func aesEncrypt(key:String, iv:String, options:Int = kCCOptionPKCS7Padding) -> String? {
        guard let keyData = Self.validatedData(from: key, lengths: [kCCKeySizeAES128, kCCKeySizeAES192, kCCKeySizeAES256]),
              let ivData = Self.validatedData(from: iv, lengths: [kCCBlockSizeAES128]),
              let data = self.data(using: .utf8) else {
            return nil
        }
        return Self.crypt(input: data, operation: CCOperation(kCCEncrypt), algorithm: CCAlgorithm(kCCAlgorithmAES), options: CCOptions(options), key: keyData, iv: ivData)?.base64EncodedString(options: .lineLength64Characters)
    }
    
    /**
     Data转MD5
     */
    static func md5(data: Data, uppercased: Bool = false) -> String {
        let digest = Insecure.MD5.hash(data: data)
        return Self.hexString(from: digest, uppercased: uppercased)
    }
    
    /**
     Data转SHA1
     */
    static func sha1(data: Data, uppercased: Bool = false) -> String {
        let digest = Insecure.SHA1.hash(data: data)
        return Self.hexString(from: digest, uppercased: uppercased)
    }
    
    /**
     Data转SHA256
     */
    static func sha256(data: Data, uppercased: Bool = false) -> String {
        let digest = SHA256.hash(data: data)
        return Self.hexString(from: digest, uppercased: uppercased)
    }
    
    /**
     文件路径转MD5
     */
    static func md5(fileAtPath path: String, uppercased: Bool = false) -> String? {
        guard let stream = InputStream(fileAtPath: path) else { return nil }
        stream.open()
        defer { stream.close() }
        var hasher = Insecure.MD5()
        guard Self.updateDigest(&hasher, with: stream) else { return nil }
        let digest = hasher.finalize()
        return Self.hexString(from: digest, uppercased: uppercased)
    }
    
    /**
     文件路径转SHA1
     */
    static func sha1(fileAtPath path: String, uppercased: Bool = false) -> String? {
        guard let stream = InputStream(fileAtPath: path) else { return nil }
        stream.open()
        defer { stream.close() }
        var hasher = Insecure.SHA1()
        guard Self.updateDigest(&hasher, with: stream) else { return nil }
        let digest = hasher.finalize()
        return Self.hexString(from: digest, uppercased: uppercased)
    }
    
    /**
     文件路径转SHA256
     */
    static func sha256(fileAtPath path: String, uppercased: Bool = false) -> String? {
        guard let stream = InputStream(fileAtPath: path) else { return nil }
        stream.open()
        defer { stream.close() }
        var hasher = SHA256()
        guard Self.updateDigest(&hasher, with: stream) else { return nil }
        let digest = hasher.finalize()
        return Self.hexString(from: digest, uppercased: uppercased)
    }
    
    private static func hexString(from bytes: some Sequence<UInt8>, uppercased: Bool) -> String {
        return bytes.map { byte in
            let value = String(format: "%02x", byte)
            return uppercased ? value.uppercased() : value
        }.joined()
    }

    /**
     校验 key / iv 长度并转 UTF-8 Data
     */
    private static func validatedData(from value: String, lengths: [Int]) -> Data? {
        guard let data = value.data(using: .utf8), lengths.contains(data.count) else {
            return nil
        }
        return data
    }

    /**
     统一加解密实现（DES / AES）
     */
    private static func crypt(input: Data, operation: CCOperation, algorithm: CCAlgorithm, options: CCOptions, key: Data, iv: Data) -> Data? {
        let outputLength = input.count + Swift.max(kCCBlockSizeAES128, kCCBlockSizeDES)
        guard let output = NSMutableData(length: outputLength) else { return nil }
        var bytesProcessed: size_t = 0

        let status = key.withUnsafeBytes { keyBytes in
            iv.withUnsafeBytes { ivBytes in
                input.withUnsafeBytes { inputBytes in
                    CCCrypt(operation,
                            algorithm,
                            options,
                            keyBytes.baseAddress,
                            key.count,
                            ivBytes.baseAddress,
                            inputBytes.baseAddress,
                            input.count,
                            output.mutableBytes,
                            output.length,
                            &bytesProcessed)
                }
            }
        }

        guard status == kCCSuccess else { return nil }
        output.length = bytesProcessed
        return output as Data
    }

    /**
     以流式方式读取文件并更新哈希，避免整文件载入内存
     */
    private static func updateDigest<H: HashFunction>(_ hasher: inout H, with stream: InputStream, chunkSize: Int = 64 * 1024) -> Bool {
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: chunkSize)
        defer { buffer.deallocate() }

        while stream.hasBytesAvailable {
            let readCount = stream.read(buffer, maxLength: chunkSize)
            if readCount < 0 {
                return false
            }
            if readCount == 0 {
                break
            }
            hasher.update(data: Data(bytes: buffer, count: readCount))
        }
        return stream.streamStatus != .error
    }
}
