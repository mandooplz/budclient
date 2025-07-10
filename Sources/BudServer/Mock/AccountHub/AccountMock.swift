//
//  AccountMock.swift
//  BudClient
//
//  Created by 김민우 on 6/23/25.
//
import Foundation
import Values


// MARK: Link
@Server
final class AccountMock: Sendable {
    // MARK: core
    init(email: String, password: String) {
        self.email = email
        self.password = password
        
        AccountMockManager.register(self)
    }
    init(token: GoogleToken) {
        self.token = token
        
        AccountMockManager.register(self)
    }
    func delete() {
        AccountMockManager.unregister(self.id)
    }
    
    
    // MARK: state
    nonisolated let id = ID()
    nonisolated let user = UserID()
    
    var email: String?
    var password: String?
    
    var token: GoogleToken?
    
    
    // MARK: value
    @Server
    struct ID: Sendable, Hashable {
        let value: UUID
        nonisolated init(value: UUID = UUID()) {
            self.value = value
        }
        
        var isExist: Bool {
            AccountMockManager.container[self] != nil
        }
        var ref: AccountMock? {
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
