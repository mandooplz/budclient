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
final class EmailRegisterFormMock: Sendable {
    // MARK: core
    init(accountHub: AccountHubMock,
         ticket: AccountHubMock.Ticket) {
        self.accountHub = accountHub
        self.ticket = ticket

        EmailRegisterFormMockManager.register(self)
    }
    func delete() {
        EmailRegisterFormMockManager.unregister(self.id)
    }
    

    // MARK: state
    nonisolated let id = ID()
    nonisolated let ticket: AccountHubMock.Ticket
    nonisolated let accountHub: AccountHubMock
    
    var email: String?
    var password: String?
    
    var issue: (any Issuable)?

    
    // MARK: action
    func submit() {
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
    func remove() {
        // mutate
        accountHub.emailRegisterForms[ticket] = nil
        self.delete()
    }

    
    // MARK: value
    @Server
    struct ID: Sendable, Hashable {
        let value: UUID
        nonisolated init(_ value: UUID = UUID()) {
            self.value = value
        }
        
        var isExist: Bool {
            EmailRegisterFormMockManager.container[self] != nil
        }
        var ref: EmailRegisterFormMock? {
            EmailRegisterFormMockManager.container[self]
        }
    }
    enum Error: String, Swift.Error {
        case emailIsNil, passwordIsNil
        case emailDuplicate
    }
}

// MARK: Object Manager
@Server
fileprivate final class EmailRegisterFormMockManager: Sendable {
    fileprivate static var container: [EmailRegisterFormMock.ID: EmailRegisterFormMock] = [:]
    fileprivate static func register(_ object: EmailRegisterFormMock) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: EmailRegisterFormMock.ID) {
        container[id] = nil
    }
}
