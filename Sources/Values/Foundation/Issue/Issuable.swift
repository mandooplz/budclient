//
//  Issuable.swift
//  BudClient
//
//  Created by 김민우 on 7/3/25.
//
import Foundation


// MARK: Issuable
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
