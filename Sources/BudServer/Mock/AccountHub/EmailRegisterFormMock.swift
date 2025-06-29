//
//  RegisterFormMock.swift
//  BudClient
//
//  Created by 김민우 on 6/23/25.
//
import Foundation
import Tools


// MARK: Object
@BudServer
internal final class EmailRegisterFormMock: Sendable {
    // MARK: core
    internal init(accountHub: AccountHubMock,
                  ticket: AccountHubMock.Ticket) {
        self.id = ID(value: .init())
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
            .compactMap { $0.ref }
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
    @BudServer
    internal struct ID: Sendable, Hashable {
        internal let value: UUID
        
        internal var isExist: Bool {
            EmailRegisterFormMockManager.container[self] != nil
        }
        internal var ref: EmailRegisterFormMock? {
            EmailRegisterFormMockManager.container[self]
        }
    }
    internal enum Error: String, Swift.Error {
        case emailIsNil, passwordIsNil
        case emailDuplicate
    }
}

// MARK: Object Manager
@BudServer
fileprivate final class EmailRegisterFormMockManager: Sendable {
    fileprivate static var container: [EmailRegisterFormMock.ID: EmailRegisterFormMock] = [:]
    fileprivate static func register(_ object: EmailRegisterFormMock) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: EmailRegisterFormMock.ID) {
        container[id] = nil
    }
}
