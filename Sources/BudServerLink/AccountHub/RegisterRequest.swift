//
//  RegisterRequest.swift
//  BudClient
//
//  Created by 김민우 on 6/23/25.
//
import Foundation


// MARK: Object
@MainActor
public final class RegisterRequest: Sendable {
    // MARK: core
    public init() {
        self.id = ID(value: UUID())

        RegisterRequestManager.register(self)
    }
    internal func delete() {
        RegisterRequestManager.unregister(self.id)
    }

    // MARK: state
    public nonisolated let id: ID
    public nonisolated let accountHub = AccountHub.self
    
    public var email: String?
    public var password: String?

    // MARK: action
    public func submit() {
        // capture
        guard let email = self.email,
              let password = self.password else { return }
        let accounts = accountHub.accounts
        
        // compute
        let isDuplicate = accounts.lazy
            .compactMap { AccountManager.get($0) }
            .contains { $0.email == email }
        if isDuplicate == true { return }
        
        // mutate
        let account = Account(email: email, password: password)
        AccountHub.accounts.insert(account.id)
    }

    // MARK: value
    public struct ID: Sendable, Hashable {
        public let value: UUID
    }
}

// MARK: Object Manager
@MainActor
public final class RegisterRequestManager: Sendable {
    private static var container: [RegisterRequest.ID: RegisterRequest] = [:]
    public static func register(_ object: RegisterRequest) {
        container[object.id] = object
    }
    public static func unregister(_ id: RegisterRequest.ID) {
        container[id] = nil
    }
    public static func get(_ id: RegisterRequest.ID) -> RegisterRequest? {
        container[id]
    }
}
