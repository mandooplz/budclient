//
//  Account.swift
//  BudClient
//
//  Created by 김민우 on 6/23/25.
//
import Foundation


// MARK: Link
@MainActor
package final class AccountMock: Sendable {
    // MARK: core
    package init(email: String, password: String) {
        self.id = ID(value: UUID())
        self.userId = UUID().uuidString
        
        self.email = email
        self.password = password
        
        AccountMockManager.register(self)
    }
    internal func delete() {
        AccountMockManager.unregister(self.id)
    }
    
    
    // MARK: state
    package nonisolated let id: ID
    package nonisolated let userId: String
    
    package var email: String
    package var password: String
    
    
    // MARK: value
    package struct ID: Sendable, Hashable {
        public let value: UUID
    }
    package typealias UserID = String
}


// MARK: Object Manager
@MainActor
package final class AccountMockManager: Sendable {
    // MARK: state
    private static var container: [AccountMock.ID: AccountMock] = [:]
    
    package static func register(_ object: AccountMock) {
        container[object.id] = object
    }
    
    package static func unregister(_ id: AccountMock.ID) {
        container[id] = nil
    }
    
    package static func get(_ id: AccountMock.ID) -> AccountMock? {
        container[id]
    }
}
