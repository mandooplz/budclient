//
//  AccountMock.swift
//  BudClient
//
//  Created by 김민우 on 6/23/25.
//
import Foundation
import Tools


// MARK: Link
@BudServer
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
    @BudServer
    internal struct ID: Sendable, Hashable {
        let value: UUID
        
        var isExist: Bool {
            AccountMockManager.container[self] != nil
        }
        var ref: AccountMock? {
            AccountMockManager.container[self]
        }
    }
    internal typealias UserID = String
}


// MARK: Object Manager
@BudServer
fileprivate final class AccountMockManager: Sendable {
    // MARK: state
    fileprivate static var container: [AccountMock.ID: AccountMock] = [:]
    fileprivate static func register(_ object: AccountMock) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: AccountMock.ID) {
        container[id] = nil
    }
}
