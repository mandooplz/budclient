//
//  Auth.swift
//  BudClient
//
//  Created by 김민우 on 7/19/25.
//
import Foundation
import CryptoKit


// MARK: Email
public struct Email: Sendable, Hashable {
    public let value: String
    
    public init?(_ value: String) {
        guard Email.isValid(value) else { return nil }
        self.value = value
    }
    
    public static func isValid(_ value: String) -> Bool {
        // Basic email regex for demonstration; adjust as needed
        let regex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        return value.range(of: regex, options: .regularExpression) != nil
    }
    
    public static func random() -> Email {
        let usernames = ["user", "test", "demo", "sample", "random", "mail", "hello", "swift", "dev", "alpha", "beta", "apple", "orange", "java", "kotlin", "typescript"]
        let domains = ["example", "testmail", "mailhost", "email", "demoapp", "swiftdev", "mydomain", "budclient", "samplehost"]
        let tlds = ["com", "net", "org", "co", "dev", "io"]
        
        let username = usernames.randomElement()! + String(Int.random(in: 1...9999))
        let domain = domains.randomElement()!
        let tld = tlds.randomElement()!
        let emailStr = "\(username)@\(domain).\(tld)"
        return Email(emailStr)!
    }
}



// MARK: Password
public struct Password: Sendable, Hashable {
    public let value: String
    
    public init?(_ value: String) {
        guard Password.isValid(value) else { return nil }
        self.value = value
    }
    
    public static func isValid(_ value: String) -> Bool {
        // Example: Minimum length 6, no whitespace
        let minLength = 6
        let hasWhitespace = value.rangeOfCharacter(from: .whitespacesAndNewlines) != nil
        return value.count >= minLength && !hasWhitespace
    }
    
    public static func random() -> Password {
        // Generate a random password (at least 8 chars, alphanumerics)
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let password = String((6..<12).map { _ in letters.randomElement()! })
        return Password(password)!
    }
}


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

