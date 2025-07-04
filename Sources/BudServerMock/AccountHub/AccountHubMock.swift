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
package final class AccountHubMock: Sendable {
    // MARK: core
    package init() { }
    
    
    // MARK: state
    package var accounts: Set<AccountMock.ID> = [
        AccountMock(email: "test@test.com", password: "123456").id
    ]
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
    package func getUser(token: GoogleToken) -> UserID? {
        accounts.lazy
            .compactMap { $0.ref }
            .first { $0.token == token }?
            .user
    }
    
    package var emailTickets: Set<Ticket> = []
    package var emailRegisterForms: [Ticket:EmailRegisterFormMock.ID] = [:]
    
    package var googleTickets: Set<Ticket> = []
    package var googleRegisterForms: [Ticket: GoogleRegisterFormMock.ID] = [:]
    
    
    // MARK: action
    package func updateEmailForms() {
        // mutate
        for ticket in emailTickets {
            let emailRegisterFormRef = EmailRegisterFormMock(accountHub: self,
                                                   ticket: ticket)
            self.emailRegisterForms[ticket] = emailRegisterFormRef.id
            emailTickets.remove(ticket)
        }
    }
    package func updateGoogleForms() {
        // mutate
        for ticket in googleTickets {
            let googleRegisterFormRef = GoogleRegisterFormMock(accountHub: self,
                                                               ticket: ticket)
            self.googleRegisterForms[ticket] = googleRegisterFormRef.id
            googleTickets.remove(ticket)
        }
    }
    
    
    // MARK: value
    package struct Ticket: Sendable, Hashable {
        package let value: UUID
        
        package init(value: UUID = UUID()) {
            self.value = value
        }
    }
    package enum Error: String, Swift.Error {
        case userNotFound, wrongPassword
    }
}
