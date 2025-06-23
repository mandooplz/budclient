//
//  RegisterRequest.swift
//  BudClient
//
//  Created by 김민우 on 6/23/25.
//
import Foundation


// MARK: Object
@MainActor
public final class RegisterFormMock: Sendable {
    // MARK: link
    public init(accountHub: AccountHubMock) {
        self.id = ID(value: .init())
        self.accountHub = accountHub

        RegisterFormMockManager.register(self)
    }
    internal func delete() {
        RegisterFormMockManager.unregister(self.id)
    }
    
    // MARK: core
    

    // MARK: state
    public nonisolated let id: ID
    public nonisolated let accountHub: AccountHubMock
    
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
        accountHub.accounts.insert(account.id)
    }

    // MARK: value
    public struct ID: Sendable, Hashable {
        public let value: UUID
    }
}

// MARK: Object Manager
@MainActor
public final class RegisterFormMockManager: Sendable {
    private static var container: [RegisterFormMock.ID: RegisterFormMock] = [:]
    public static func register(_ object: RegisterFormMock) {
        container[object.id] = object
    }
    public static func unregister(_ id: RegisterFormMock.ID) {
        container[id] = nil
    }
    public static func get(_ id: RegisterFormMock.ID) -> RegisterFormMock? {
        container[id]
    }
}
