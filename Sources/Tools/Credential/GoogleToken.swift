//
//  GoogleToken.swift
//  BudClient
//
//  Created by 김민우 on 7/4/25.
//
import Foundation
import CryptoKit


public struct GoogleToken: Sendable, Hashable {
    public let idToken: String
    public let accessToken: String
    
    public init(idToken: String, accessToken: String) {
        self.idToken = idToken
        self.accessToken = accessToken
    }
    
    package func getValue() -> String {
        let combined = idToken + ":" + accessToken
        
        // SHA256 해시를 사용한 결정론적 user id 생성
        let data = combined.data(using: .utf8)!
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    package static func random() -> GoogleToken {
        return .init(idToken: Token.random().value,
                     accessToken: Token.random().value)
    }
}
