//
//  EmailRegisterForm.swift
//  BudClient
//
//  Created by 김민우 on 6/24/25.
//
import Foundation
import Values
import FirebaseAuth


// MARK: Object
@MainActor
package final class EmailRegisterForm: EmailRegisterFormInterface {
    // MARK: core
    init(accountHub: AccountHub.ID,
         ticket: CreateFormTicket) {
        self.accountHub = accountHub
        self.ticket = ticket
        
        EmailRegisterFormManager.register(self)
    }
    package func delete() {
        EmailRegisterFormManager.unregister(self.id)
    }
    
    
    // MARK: state
    package nonisolated let id = ID()
    nonisolated let ticket: CreateFormTicket
    nonisolated let accountHub: AccountHub.ID
    
    private var email: String?
    package func setEmail(_ value: String) async {
        self.email = value
    }
    
    private var password: String?
    package func setPassword(_ value: String) async {
        self.password = value
    }

    
    // MARK: action
    package func submit() async throws {
        // capture
        guard let email else { throw Error.emailIsNil }
        guard let password else { throw Error.passwordIsNil }
        
        // mutate
        try await Auth.auth().createUser(withEmail: email,
                                         password: password)
    }
    package func remove() async throws {
        // mutate
        accountHub.ref?.emailRegisterForms[ticket] = nil
        self.delete()
    }

    
    // MARK: value
    @MainActor
    package struct ID: EmailRegisterFormIdentity {
        let value = UUID()
        nonisolated init() { }
        
        package var isExist: Bool {
            EmailRegisterFormManager.container[self] != nil
        }
        package var ref: EmailRegisterForm? {
            EmailRegisterFormManager.container[self]
        }
    }
    package enum Error: String, Swift.Error {
        case emailIsNil, passwordIsNil
    }
}



// MARK: Object Manager
@MainActor
fileprivate final class EmailRegisterFormManager: Sendable {
    fileprivate static var container: [EmailRegisterForm.ID: EmailRegisterForm] = [:]
    fileprivate static func register(_ object: EmailRegisterForm) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: EmailRegisterForm.ID) {
        container[id] = nil
    }
}
