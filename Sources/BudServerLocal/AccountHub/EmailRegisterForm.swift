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
package final class EmailRegisterForm: Sendable {
    // MARK: core
    package init(accountHubRef: AccountHub,
                  ticket: CreateEmailForm) {
        self.accountHubRef = accountHubRef
        self.ticket = ticket
        
        EmailRegisterFormManager.register(self)
    }
    package func delete() {
        EmailRegisterFormManager.unregister(self.id)
    }
    
    
    // MARK: state
    package nonisolated let id = EmailRegisterFormID()
    package nonisolated let ticket: CreateEmailForm
    package nonisolated let accountHubRef: AccountHub
    
    package var email: String?
    package var password: String?
    
    package var issue: (any Issuable)?

    
    // MARK: action
    package func submit() async {
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
    package func remove() async {
        // mutate
        accountHubRef.emailRegisterForms[ticket] = nil
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
package final class EmailRegisterFormManager: Sendable {
    fileprivate static var container: [EmailRegisterFormID: EmailRegisterForm] = [:]
    fileprivate static func register(_ object: EmailRegisterForm) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: EmailRegisterFormID) {
        container[id] = nil
    }
    package static func get(_ id: EmailRegisterFormID) -> EmailRegisterForm? {
        container[id]
    }
}
