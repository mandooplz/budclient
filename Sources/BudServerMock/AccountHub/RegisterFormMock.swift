//
//  RegisterRequest.swift
//  BudClient
//
//  Created by 김민우 on 6/23/25.
//
import Foundation
import Tools


// MARK: Object
@MainActor
public final class RegisterFormMock: Sendable {
    // MARK: core
    public init(accountHub: AccountHubMock,
                ticket: AccountHubMock.Ticket) {
        self.id = ID()
        self.accountHub = accountHub
        self.ticket = ticket

        RegisterFormMockManager.register(self)
    }
    internal func delete() {
        RegisterFormMockManager.unregister(self.id)
    }
    

    // MARK: state
    public nonisolated let id: ID
    public nonisolated let ticket: AccountHubMock.Ticket
    public nonisolated let accountHub: AccountHubMock
    
    public var email: String?
    public var password: String?
    
    public var issue: Issue?

    
    // MARK: action
    public func submit() {
        // capture
        guard let email else {
            self.issue = Issue(isKnown: true, reason: Error.emailIsNil); return
        }
        guard let password else {
            self.issue = Issue(isKnown: true, reason: Error.passwordIsNil); return
        }
        let accounts = accountHub.accounts
        
        // compute
        let isDuplicate = accounts.lazy
            .compactMap { AccountManager.get($0) }
            .contains { $0.email == email }
        if isDuplicate == true {
            self.issue = Issue(isKnown: true, reason: Error.emailDuplicate)
            return
        }
        
        // mutate
        let account = Account(email: email, password: password)
        accountHub.accounts.insert(account.id)
    }
    public func remove() {
        // mutate
        accountHub.registerForms[ticket] = nil
        self.delete()
    }

    
    // MARK: value
    public struct ID: Sendable, Hashable {
        public let value: UUID
        public init(value: UUID = UUID()) {
            self.value = value
        }
    }
    public enum Error: String, Swift.Error {
        case emailIsNil, passwordIsNil
        case emailDuplicate
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
