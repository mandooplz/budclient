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
public final class BudServerMock: Sendable {
    // MARK: core
    public static let shared = BudServerMock()
    private init() {
        self.id = ID(value: .init())
    }
    
    
    // MARK: state
    public nonisolated let id: ID
    
    public let accountHub = AccountHubMock.shared
    
    
    // MARK: value
    public struct ID: Sendable, Hashable {
        public let value: UUID
    }
}
