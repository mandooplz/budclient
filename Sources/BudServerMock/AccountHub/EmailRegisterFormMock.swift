//
//  RegisterFormMock.swift
//  BudClient
//
//  Created by 김민우 on 6/23/25.
//
import Foundation
import Tools


// MARK: Object
@Server
package final class EmailRegisterFormMock: Sendable {
    // MARK: core
    package init(accountHub: AccountHubMock,
         ticket: CreateEmailForm) {
        self.accountHub = accountHub
        self.ticket = ticket

        EmailRegisterFormMockManager.register(self)
    }
    package func delete() {
        EmailRegisterFormMockManager.unregister(self.id)
    }
    

    // MARK: state
    package nonisolated let id = EmailRegisterFormID()
    package nonisolated let ticket: CreateEmailForm
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
    package func remove() {
        // mutate
        accountHub.emailRegisterForms[ticket] = nil
        self.delete()
    }

    
    // MARK: value
    package enum Error: String, Swift.Error {
        case emailIsNil, passwordIsNil
        case emailDuplicate
    }
}

// MARK: Object Manager
@Server
package final class EmailRegisterFormMockManager: Sendable {
    fileprivate static var container: [EmailRegisterFormID: EmailRegisterFormMock] = [:]
    fileprivate static func register(_ object: EmailRegisterFormMock) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: EmailRegisterFormID) {
        container[id] = nil
    }
    package static func get(_ id: EmailRegisterFormID) -> EmailRegisterFormMock? {
        container[id]
    }
    package static func isExist(_ id: EmailRegisterFormID) -> Bool {
        container[id] != nil
    }
}
