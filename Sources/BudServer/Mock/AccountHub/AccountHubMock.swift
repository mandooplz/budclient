//
//  AccountHubMock.swift
//  BudClient
//
//  Created by 김민우 on 6/23/25.
//
import Foundation
import Tools


// MARK: Object
@Server
internal final class AccountHubMock: Sendable {
    // MARK: core
    init() { }
    
    
    // MARK: state
    var accounts: Set<AccountMock.ID> = [
        AccountMock(email: "test@test.com", password: "123456").id
    ]
    func isExist(email: String, password: String) -> Bool {
        accounts.lazy
            .compactMap { $0.ref }
            .contains { $0.email == email && $0.password == password }
    }
    func isExist(token: GoogleToken) -> Bool {
        accounts.lazy
            .compactMap { $0.ref }
            .contains { $0.token == token }
    }
    func getUser(email: String, password: String) throws -> UserID {
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
    func getUser(token: GoogleToken) -> UserID? {
        accounts.lazy
            .compactMap { $0.ref }
            .first { $0.token == token }?
            .user
    }
    
    var emailTickets: Set<Ticket> = []
    var emailRegisterForms: [Ticket:EmailRegisterFormMock.ID] = [:]
    
    var googleTickets: Set<Ticket> = []
    var googleRegisterForms: [Ticket: GoogleRegisterFormMock.ID] = [:]
    
    
    // MARK: action
    internal func updateEmailForms() {
        // mutate
        for ticket in emailTickets {
            let emailRegisterFormRef = EmailRegisterFormMock(accountHub: self,
                                                   ticket: ticket)
            self.emailRegisterForms[ticket] = emailRegisterFormRef.id
            emailTickets.remove(ticket)
        }
    }
    internal func updateGoogleForms() {
        // mutate
        for ticket in googleTickets {
            let googleRegisterFormRef = GoogleRegisterFormMock(accountHub: self,
                                                               ticket: ticket)
            self.googleRegisterForms[ticket] = googleRegisterFormRef.id
            googleTickets.remove(ticket)
        }
    }
    
    
    // MARK: value
    internal struct Ticket: Sendable, Hashable {
        internal let value: UUID
        
        internal init(value: UUID = UUID()) {
            self.value = value
        }
    }
    internal enum Error: String, Swift.Error {
        case userNotFound, wrongPassword
    }
}
