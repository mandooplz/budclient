//
//  BudServerMock.swift
//  BudClient
//
//  Created by 김민우 on 6/23/25.
//
import Foundation
import Tools


// MARK: System
@MainActor
package final class BudServerMock: Sendable {
    // MARK: core
    package static let shared = BudServerMock()
    internal init() {
        self.id = ID(value: .init())
    }
    
    
    // MARK: state
    package nonisolated let id: ID
    
    package let accountHub = AccountHubMock.shared
    
    
    // MARK: value
    package struct ID: Sendable, Hashable {
        package let value: UUID
    }
}
