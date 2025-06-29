//
//  AccountMock.swift
//  BudClient
//
//  Created by 김민우 on 6/23/25.
//
import Foundation


// MARK: Link
@MainActor
internal final class AccountMock: Sendable {
    // MARK: core
    internal init(email: String, password: String) {
        self.id = ID(value: UUID())
        self.userId = UUID().uuidString
        
        self.email = email
        self.password = password
        
        AccountMockManager.register(self)
    }
    internal init(idToken: String, accessToken: String) {
        self.id = ID(value: .init())
        self.userId = UUID().uuidString
        
        self.idToken = idToken
        self.accessToken = accessToken
        
        AccountMockManager.register(self)
    }
    internal func delete() {
        AccountMockManager.unregister(self.id)
    }
    
    
    // MARK: state
    internal nonisolated let id: ID
    internal nonisolated let userId: String
    
    internal var email: String?
    internal var password: String?
    
    internal var idToken: String?
    internal var accessToken: String?
    
    
    // MARK: value
    internal struct ID: Sendable, Hashable {
        let value: UUID
    }
    internal typealias UserID = String
}


// MARK: Object Manager
@MainActor
internal final class AccountMockManager: Sendable {
    // MARK: state
    private static var container: [AccountMock.ID: AccountMock] = [:]
    internal static func register(_ object: AccountMock) {
        container[object.id] = object
    }
    internal static func unregister(_ id: AccountMock.ID) {
        container[id] = nil
    }
    internal static func get(_ id: AccountMock.ID) -> AccountMock? {
        container[id]
    }
}
