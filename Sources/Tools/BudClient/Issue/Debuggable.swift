//
//  Debuggable.swift
//  BudClient
//
//  Created by 김민우 on 7/3/25.
//
import Foundation


// MARK: Debuggable
@MainActor
public protocol Debuggable: AnyObject, Sendable {
    var issue: (any Issuable)? { get set }
}

@MainActor
public extension Debuggable {
    var isIssueOccurred: Bool { self.issue != nil }
    
    func setIssue<E: RawRepresentable<String>>(_ error: E) {
        self.issue = KnownIssue(error)
    }
    func setUnknownIssue(_ error: Error) {
        self.issue = UnknownIssue(error)
    }
}
