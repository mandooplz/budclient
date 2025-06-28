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
package final class RegisterFormMock: Sendable {
    // MARK: core
    package init(accountHub: AccountHubMock,
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
    package nonisolated let id: ID
    package nonisolated let ticket: AccountHubMock.Ticket
    package nonisolated let accountHub: AccountHubMock
    
    package var email: String?
    package var password: String?
    
    package var issue: (any Issuable)?

    
    // MARK: action
    package func submit() {
        // capture
        guard let email else {
            self.issue = KnownIssue(Error.emailIsNil)
            return
        }
        guard let password else {
            self.issue = KnownIssue(Error.passwordIsNil)
            return
        }
        let accounts = accountHub.accounts
        
        // compute
        let isDuplicate = accounts.lazy
            .compactMap { AccountMockManager.get($0) }
            .contains { $0.email == email }
        guard isDuplicate == false else {
            self.issue = KnownIssue(Error.emailDuplicate)
            return
        }
        
        // mutate
        let account = AccountMock(email: email, password: password)
        accountHub.accounts.insert(account.id)
    }
    package func remove() {
        // mutate
        accountHub.registerForms[ticket] = nil
        self.delete()
    }

    
    // MARK: value
    package struct ID: Sendable, Hashable {
        public let value: UUID
        public init(value: UUID = UUID()) {
            self.value = value
        }
    }
    package enum Error: String, Swift.Error {
        case emailIsNil, passwordIsNil
        case emailDuplicate
    }
}

// MARK: Object Manager
@MainActor
package final class RegisterFormMockManager: Sendable {
    private static var container: [RegisterFormMock.ID: RegisterFormMock] = [:]
    package static func register(_ object: RegisterFormMock) {
        container[object.id] = object
    }
    package static func unregister(_ id: RegisterFormMock.ID) {
        container[id] = nil
    }
    package static func get(_ id: RegisterFormMock.ID) -> RegisterFormMock? {
        container[id]
    }
}
