//
//  AccountHubMock.swift
//  BudClient
//
//  Created by 김민우 on 6/23/25.
//
import Foundation
import Values
import Collections


// MARK: Object
@Server
package final class AccountHubMock: AccountHubInterface {
    // MARK: core
    init() {
        self.accounts = [AccountMock(email: "test@test.com", password: "123456").id]
        
        AccountHubMockManager.register(self)
    }
    
    
    // MARK: state
    package nonisolated let id = ID()
    
    private var clientIds: [String: String] = ["BudClient":"SAMPLE_ID_123456"]
    package func getGoogleClientID(for systemName: String) async -> String? {
        return clientIds[systemName]
    }
    
    var accounts: Set<AccountMock.ID>
    package func isExist(email: String, password: String) -> Bool {
        accounts.lazy
            .compactMap { $0.ref }
            .contains { $0.email == email && $0.password == password }
    }
    package func isExist(token: GoogleToken) -> Bool {
        accounts.lazy
            .compactMap { $0.ref }
            .contains { $0.token == token }
    }
    package func getUser(email: String, password: String) throws -> UserID {
        let filtered = self.accounts.lazy
            .compactMap { $0.ref }
            .filter { $0.email == email }
        
        if filtered.isEmpty { throw Error.userNotFound }
        
        
        guard let user = filtered.lazy
            .first(where: { $0.password == password })?
            .user else {
                throw Error.wrongPassword
            }
        
        return user
    }
    package func getUser(token: GoogleToken) throws -> UserID {
        let user = accounts.lazy
            .compactMap { $0.ref }
            .first { $0.token == token }?
            .user
        
        guard let result = user else { throw Error.userNotFound }
        return result
    }
    
    private var tickets: Deque<CreateFormTicket> = []
    package func appendTicket(_ ticket: CreateFormTicket) async {
        tickets.append(ticket)
    }
    
    var emailRegisterForms: [CreateFormTicket: EmailRegisterFormMock.ID] = [:]
    var googleRegisterForms: [CreateFormTicket: GoogleRegisterFormMock.ID] = [:]
    package func getEmailRegisterForm(ticket: CreateFormTicket) async -> EmailRegisterFormMock.ID? {
        guard ticket.formType == .email else { return nil }
        return emailRegisterForms[ticket]
    }
    package func getGoogleRegisterForm(ticket: CreateFormTicket) async -> GoogleRegisterFormMock.ID? {
        guard ticket.formType == .google else { return nil }
        return googleRegisterForms[ticket]
    }
    
    
    
    // MARK: action
    package func createFormsFromTickets() {
        let accountHub = self.id
        while tickets.isEmpty == false {
            let ticket = tickets.removeFirst()
            switch ticket.formType {
            case .email:
                let emailRegisterFormRef = EmailRegisterFormMock(accountHub: accountHub,
                                                                 ticket: ticket)
                self.emailRegisterForms[ticket] = emailRegisterFormRef.id
            case .google:
                let googleRegisterFormRef = GoogleRegisterFormMock(accountHub: accountHub,
                                                                   ticket: ticket)
                self.googleRegisterForms[ticket] = googleRegisterFormRef.id
            }
        }
    }

    
    // MARK: value
    @Server
    package struct ID: AccountHubIdentity {
        let value: String = "AccountHubMock"
        nonisolated init() { }
        
        package var isExist: Bool {
            AccountHubMockManager.container[self] != nil
        }
        package var ref: AccountHubMock? {
            AccountHubMockManager.container[self]
        }
    }
    package enum Error: String, Swift.Error {
        case userNotFound, wrongPassword
    }
}


// MARK: ObjectManager
@Server
fileprivate final class AccountHubMockManager: Sendable {
    fileprivate static var container: [AccountHubMock.ID: AccountHubMock] = [:]
    fileprivate static func register(_ object: AccountHubMock) {
        container[object.id] = object
    }
}
