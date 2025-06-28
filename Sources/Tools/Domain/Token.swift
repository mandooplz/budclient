//
//  Token.swift
//  BudClient
//
//  Created by 김민우 on 6/29/25.
//
import Foundation


// MARK: Token
public struct Token: Sendable, Hashable {
    public let value: String
    
    public init?(_ value: String) {
        guard Self.isValid(value) else { return nil }
        self.value = value
    }
    
    public static func isValid(_ value: String) -> Bool {
        // 예시: 비어있지 않은 문자열만 유효하다고 판단
        return !value.isEmpty
    }
    
    public static func random(length: Int = 32) -> Token {
        let chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let value = String((0..<length).compactMap { _ in chars.randomElement() })
        // random은 항상 유효성을 만족한다고 가정
        return Token(value)!
    }
}
