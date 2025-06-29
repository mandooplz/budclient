//
//  EmailRegisterForm.swift
//  BudClient
//
//  Created by 김민우 on 6/24/25.
//
import Foundation
import Tools
import FirebaseAuth


// MARK: Object
@BudServer
internal final class EmailRegisterForm: Sendable {
    // MARK: core
    internal init(accountHubRef: AccountHub,
                  ticket: AccountHub.Ticket) {
        self.accountHubRef = accountHubRef
        self.id = ID(value: .init())
        self.ticket = ticket
        
        EmailRegisterFormManager.register(self)
    }
    internal func delete() {
        EmailRegisterFormManager.unregister(self.id)
    }
    
    
    // MARK: state
    internal nonisolated let id: ID
    internal nonisolated let ticket: AccountHub.Ticket
    internal nonisolated let accountHubRef: AccountHub
    
    internal var email: String?
    internal var password: String?
    
    internal var issue: (any Issuable)?

    
    // MARK: action
    internal func submit() async {
        // capture
        guard let email else {
            self.issue = KnownIssue(Error.emailIsNil)
            return
        }
        guard let password else {
            self.issue = KnownIssue(Error.passwordIsNil)
            return
        }
        
        // mutate
        do {
            try await Auth.auth().createUser(withEmail: email,
                                             password: password)
        } catch {
            self.issue = UnknownIssue(error)
            return
        }
    }
    internal func remove() async {
        // mutate
        accountHubRef.emailRegisterForms[ticket] = nil
        self.delete()
    }

    
    // MARK: value
    @BudServer
    internal struct ID: Sendable, Hashable {
        internal let value: UUID
        
        internal var isExist: Bool {
            EmailRegisterFormManager.container[self] != nil
        }
        internal var ref: EmailRegisterForm? {
            EmailRegisterFormManager.container[self]
        }
    }
    internal enum Error: String, Swift.Error {
        case emailIsNil, passwordIsNil
        case emailDuplicate
    }
}



// MARK: Object Manager
@BudServer
fileprivate final class EmailRegisterFormManager: Sendable {
    fileprivate static var container: [EmailRegisterForm.ID: EmailRegisterForm] = [:]
    fileprivate static func register(_ object: EmailRegisterForm) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: EmailRegisterForm.ID) {
        container[id] = nil
    }
}
