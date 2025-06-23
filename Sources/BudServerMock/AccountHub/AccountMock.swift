//
//  Account.swift
//  BudClient
//
//  Created by 김민우 on 6/23/25.
//
import Foundation


// MARK: Link
@MainActor
public final class Account: Sendable {
    // MARK: core
    public init(email: String, password: String) {
        self.id = ID(value: UUID())
        self.userId = UUID().uuidString
        
        self.email = email
        self.password = password
        
        AccountManager.register(self)
    }
    internal func delete() {
        AccountManager.unregister(self.id)
    }
    
    
    // MARK: state
    public nonisolated let id: ID
    public nonisolated let userId: String
    
    public var email: String
    public var password: String
    
    
    // MARK: value
    public struct ID: Sendable, Hashable {
        public let value: UUID
    }
    public typealias UserID = String
}


// MARK: Object Manager
@MainActor
public final class AccountManager: Sendable {
    // MARK: state
    private static var container: [Account.ID: Account] = [:]
    
    public static func register(_ object: Account) {
        container[object.id] = object
    }
    
    public static func unregister(_ id: Account.ID) {
        container[id] = nil
    }
    
    public static func get(_ id: Account.ID) -> Account? {
        container[id]
    }
}
