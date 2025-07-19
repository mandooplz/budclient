//
//  IssueRepresentable.swift
//  BudClient
//
//  Created by 김민우 on 7/19/25.
//
import Foundation


// MARK: IssueRepresentable
public protocol IssueRepresentable: Swift.Error, Hashable, Sendable, Identifiable {
    var id: UUID { get }
    var isKnown: Bool { get }
    var reason: String { get }
}


extension IssueRepresentable {
    public var localizedDescription: String {
        self.reason
    }
}
