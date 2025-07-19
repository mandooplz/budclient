//
//  Debuggable.swift
//  BudClient
//
//  Created by 김민우 on 7/19/25.
//
import Foundation


// MARK: Debuggable
@MainActor
public protocol Debuggable: AnyObject, Sendable {
    var issue: (any IssueRepresentable)? { get set }
}

@MainActor
public extension Debuggable {
    var isIssueOccurred: Bool { self.issue != nil }
    
    func setIssue<E: RawRepresentable<String>>(_ error: E) {
        self.issue = KnownIssue(error)
    }
    
    func setUnknownIssue(_ error: Error, location: String = #function) {
        self.issue = UnknownIssue(error)
    }
}
