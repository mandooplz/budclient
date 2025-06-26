//
//  Issue.swift
//  BudClient
//
//  Created by 김민우 on 6/23/25.
//
import Foundation


// MARK: value
public protocol Issuable: Swift.Error, Hashable, Sendable, Identifiable {
    var id: UUID { get }
    var isKnown: Bool { get }
    var reason: String { get }
}

extension Issuable {
    public var localizedDescription: String {
        self.reason
    }
}


// MARK: KnownIssue
public struct KnownIssue: Issuable {
    public let id = UUID()
    public let isKnown: Bool = true
    public let reason: String
    
    public init(reason: String) {
        self.reason = reason
    }
    
    public init<ObjectError: RawRepresentable<String>>(_ reason: ObjectError) {
        self.reason = reason.rawValue
    }
}


// MARK: UnknownIssue
public struct UnknownIssue: Issuable {
    public let id = UUID()
    public let isKnown: Bool = false
    public let reason: String
    
    public init(reason: String) {
        self.reason = reason
    }
    
    public init<ObjectError: Error>(_ reason: ObjectError) {
        self.reason = reason.localizedDescription
    }
}


// MARK: Issue
public struct Issue: Error, Hashable, Sendable, Identifiable {
    public let id = UUID()
    public let isKnown: Bool
    public let reason: String
    
    public var localizedDescription: String {
        self.reason
    }
    
    public init(isKnown: Bool, reason: String) {
        self.isKnown = isKnown
        self.reason = reason
    }
    
    public init<T: RawRepresentable<String>>(isKnown: Bool, reason: T) {
        self.isKnown = isKnown
        self.reason = reason.rawValue
    }
}
