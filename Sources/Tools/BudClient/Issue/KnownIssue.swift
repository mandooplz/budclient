//
//  KnownIssue.swift
//  BudClient
//
//  Created by 김민우 on 7/3/25.
//
import Foundation


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
