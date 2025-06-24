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
final class RegisterForm {
    // MARK: core
    init(accountHubRef: AccountHub,
        ticket: AccountHub.Ticket) {
        self.accountHubRef = accountHubRef
        self.id = .init()
        self.ticket = ticket
        
        RegisterFormManager.register(self)
    }
    func delete() {
        RegisterFormManager.unregister(self.id)
    }
    
    
    // MARK: state
    nonisolated let id: ID
    nonisolated let ticket: AccountHub.Ticket
    nonisolated let accountHubRef: AccountHub
    
    var email: String?
    var password: String?
    
    var issue: Issue?

    
    // MARK: action
    func submit() async {
        // capture
        guard let email else {
            self.issue = Issue(isKnown: true, reason: Error.emailIsNil); return
        }
        guard let password else {
            self.issue = Issue(isKnown: true, reason: Error.passwordIsNil); return
        }
        
        // mutate
        do {
            try await Auth.auth().createUser(withEmail: email,
                                             password: password)
        } catch {
            self.issue = Issue(isKnown: false,
                               reason: error.localizedDescription)
        }
    }
    func remove() async {
        // mutate
        accountHubRef.registerForms[ticket] = nil
        self.delete()
    }

    
    // MARK: value
    struct ID: Sendable, Hashable {
        let value: UUID
        init(value: UUID = UUID()) {
            self.value = value
        }
    }
    enum Error: String, Swift.Error {
        case emailIsNil, passwordIsNil
        case emailDuplicate
    }
}



// MARK: Object Manager
@Server
final class RegisterFormManager {
    private static var container: [RegisterForm.ID: RegisterForm] = [:]
    public static func register(_ object: RegisterForm) {
        container[object.id] = object
    }
    
    public static func unregister(_ id: RegisterForm.ID) {
        container[id] = nil
    }
    
    public static func get(_ id: RegisterForm.ID) -> RegisterForm? {
        container[id]
    }
}
