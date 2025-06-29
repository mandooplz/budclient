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
internal final class BudServerMock: Sendable {
    // MARK: core
    internal static let shared = BudServerMock()
    internal init() {
        self.id = ID(value: .init())
    }
    
    
    // MARK: state
    internal nonisolated let id: ID
    
    internal let accountHub = AccountHubMock.shared
    
    
    // MARK: value
    internal struct ID: Sendable, Hashable {
        let value: UUID
    }
}
