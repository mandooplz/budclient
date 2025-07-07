//
//  Password.swift
//  BudClient
//
//  Created by 김민우 on 6/23/25.
//


import Foundation

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
