//
//  Email.swift
//  BudClient
//
//  Created by 김민우 on 6/23/25.
//
import Foundation


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
}
