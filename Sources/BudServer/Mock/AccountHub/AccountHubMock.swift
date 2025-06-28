//
//  AccountHubMock.swift
//  BudClient
//
//  Created by 김민우 on 6/23/25.
//
import Foundation
import Tools


// MARK: Object
@MainActor
package final class AccountHubMock: Sendable {
    // MARK: core
    package static let shared = AccountHubMock()
    internal init() { }
    
    
    // MARK: state
    package var accounts: Set<AccountMock.ID> = []
    package func isExist(email: String, password: String) -> Bool {
        // capture
        let accounts = self.accounts
        
        // compute
        let isExist = accounts.lazy
            .compactMap { AccountMockManager.get($0) }
            .contains { $0.email == email && $0.password == password }
        return isExist
    }
    package func getUserId(email: String, password: String) throws -> AccountMock.UserID {
        let filtered = self.accounts.lazy
            .compactMap { AccountMockManager.get($0) }
            .filter { $0.email == email }
        
        if filtered.isEmpty { throw Error.userNotFound }
        
        guard let userId = filtered.lazy
            .first(where: { $0.password == password })?
            .userId else {
                throw Error.wrongPassword
            }
        
        return userId
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
        public let value: UUID
        
        public init(value: UUID = UUID()) {
            self.value = value
        }
    }
    package enum Error: String, Swift.Error {
        case userNotFound, wrongPassword
    }
}
