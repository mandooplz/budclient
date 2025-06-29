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
@Server
internal final class EmailRegisterForm {
    // MARK: core
    internal init(accountHubRef: AccountHub,
                  ticket: AccountHub.Ticket) {
        self.accountHubRef = accountHubRef
        self.id = .init()
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
@Server
internal final class EmailRegisterFormManager {
    private static var container: [EmailRegisterForm.ID: EmailRegisterForm] = [:]
    internal static func register(_ object: EmailRegisterForm) {
        container[object.id] = object
    }
    
    internal static func unregister(_ id: EmailRegisterForm.ID) {
        container[id] = nil
    }
    
    internal static func get(_ id: EmailRegisterForm.ID) -> EmailRegisterForm? {
        container[id]
    }
}
