//
//  RegisterForm.swift
//  BudClient
//
//  Created by 김민우 on 6/24/25.
//
import Foundation
import Tools
import FirebaseAuth


// MARK: Object
@Server
internal final class RegisterForm {
    // MARK: core
    internal init(accountHubRef: AccountHub,
        ticket: AccountHub.Ticket) {
        self.accountHubRef = accountHubRef
        self.id = .init()
        self.ticket = ticket
        
        RegisterFormManager.register(self)
    }
    internal func delete() {
        RegisterFormManager.unregister(self.id)
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
        accountHubRef.registerForms[ticket] = nil
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
internal final class RegisterFormManager {
    private static var container: [RegisterForm.ID: RegisterForm] = [:]
    internal static func register(_ object: RegisterForm) {
        container[object.id] = object
    }
    
    internal static func unregister(_ id: RegisterForm.ID) {
        container[id] = nil
    }
    
    internal static func get(_ id: RegisterForm.ID) -> RegisterForm? {
        container[id]
    }
}
