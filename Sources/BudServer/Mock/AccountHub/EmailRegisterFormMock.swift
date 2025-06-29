//
//  RegisterFormMock.swift
//  BudClient
//
//  Created by 김민우 on 6/23/25.
//
import Foundation
import Tools


// MARK: Object
@MainActor
internal final class EmailRegisterFormMock: Sendable {
    // MARK: core
    internal init(accountHub: AccountHubMock,
                ticket: AccountHubMock.Ticket) {
        self.id = ID()
        self.accountHub = accountHub
        self.ticket = ticket

        EmailRegisterFormMockManager.register(self)
    }
    internal func delete() {
        EmailRegisterFormMockManager.unregister(self.id)
    }
    

    // MARK: state
    internal nonisolated let id: ID
    internal nonisolated let ticket: AccountHubMock.Ticket
    internal nonisolated let accountHub: AccountHubMock
    
    internal var email: String?
    internal var password: String?
    
    internal var issue: (any Issuable)?

    
    // MARK: action
    internal func submit() {
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
    internal func remove() {
        // mutate
        accountHub.emailRegisterForms[ticket] = nil
        self.delete()
    }

    
    // MARK: value
    internal struct ID: Sendable, Hashable {
        internal let value: UUID
        internal init(value: UUID = UUID()) {
            self.value = value
        }
    }
    internal enum Error: String, Swift.Error {
        case emailIsNil, passwordIsNil
        case emailDuplicate
    }
}

// MARK: Object Manager
@MainActor
internal final class EmailRegisterFormMockManager: Sendable {
    private static var container: [EmailRegisterFormMock.ID: EmailRegisterFormMock] = [:]
    internal static func register(_ object: EmailRegisterFormMock) {
        container[object.id] = object
    }
    internal static func unregister(_ id: EmailRegisterFormMock.ID) {
        container[id] = nil
    }
    internal static func get(_ id: EmailRegisterFormMock.ID) -> EmailRegisterFormMock? {
        container[id]
    }
}
