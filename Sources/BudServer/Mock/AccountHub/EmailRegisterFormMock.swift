//
//  RegisterFormMock.swift
//  BudClient
//
//  Created by 김민우 on 6/23/25.
//
import Foundation
import Values


// MARK: Object
@Server
package final class EmailRegisterFormMock: EmailRegisterFormInterface {
    // MARK: core
    init(accountHub: AccountHubMock.ID,
                 ticket: CreateFormTicket) {
        self.accountHub = accountHub
        self.ticket = ticket

        EmailRegisterFormMockManager.register(self)
    }
    func delete() {
        EmailRegisterFormMockManager.unregister(self.id)
    }
    

    // MARK: state
    package nonisolated let id = ID()
    package nonisolated let ticket: CreateFormTicket
    package nonisolated let accountHub: AccountHubMock.ID
    
    private var email: String?
    private var password: String?
    package func setEmail(_ value: String) async {
        self.email = value
    }
    package func setPassword(_ value: String) async {
        self.password = value
    }
    

    
    // MARK: action
    package func submit() throws {
        // capture
        guard let email else { throw Error.emailIsNil }
        guard let password else { throw Error.passwordIsNil }
        guard let accountHubRef = accountHub.ref else { return }
        let accounts = accountHub.ref!.accounts
        
        // compute
        let isDuplicate = accounts.lazy
            .compactMap { $0.ref }
            .contains { $0.email == email }
        guard isDuplicate == false else { throw Error.emailDuplicate }
        
        // mutate
        let account = AccountMock(email: email, password: password)
        accountHubRef.accounts.insert(account.id)
    }
    package func remove() {
        // mutate
        accountHub.ref?.emailRegisterForms[ticket] = nil
        self.delete()
    }

    
    // MARK: value
    @Server
    package struct ID: EmailRegisterFormIdentity {
        let value: UUID = UUID()
        nonisolated init() { }
        
        package var isExist: Bool {
            EmailRegisterFormMockManager.container[self] != nil
        }
        package var ref: EmailRegisterFormMock? {
            EmailRegisterFormMockManager.container[self]
        }
    }
    package enum Error: String, Swift.Error {
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
