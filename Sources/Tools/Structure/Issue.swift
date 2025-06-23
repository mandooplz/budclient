//
//  Issue.swift
//  BudClient
//
//  Created by 김민우 on 6/23/25.
//
import Foundation


// MARK: Issue
public struct Issue: Error, Hashable, Sendable, Identifiable {
    public let id = UUID()
    public let isKnown: Bool
    public let reason: String
    
    public init(isKnown: Bool, reason: String) {
        self.isKnown = isKnown
        self.reason = reason
    }
    
    public init<T: RawRepresentable<String>>(isKnown: Bool, reason: T) {
        self.isKnown = isKnown
        self.reason = reason.rawValue
    }
}
