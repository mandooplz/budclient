//
//  AccountMock.swift
//  BudClient
//
//  Created by 김민우 on 6/23/25.
//
import Foundation
import Tools


// MARK: Link
@Server
package final class AccountMock: Sendable {
    // MARK: core
    package init(email: String, password: String) {
        self.email = email
        self.password = password
        
        AccountMockManager.register(self)
    }
    package init(token: GoogleToken) {
        self.token = token
        
        AccountMockManager.register(self)
    }
    package func delete() {
        AccountMockManager.unregister(self.id)
    }
    
    
    // MARK: state
    package nonisolated let id = ID()
    package nonisolated let user = UserID()
    
    package var email: String?
    package var password: String?
    
    package var token: GoogleToken?
    
    
    // MARK: value
    @Server
    package struct ID: Sendable, Hashable {
        package let value: UUID
        package nonisolated init(value: UUID = UUID()) {
            self.value = value
        }
        
        package var isExist: Bool {
            AccountMockManager.container[self] != nil
        }
        package var ref: AccountMock? {
            AccountMockManager.container[self]
        }
    }
}


// MARK: Object Manager
@Server
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
