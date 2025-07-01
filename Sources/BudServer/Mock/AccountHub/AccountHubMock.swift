//
//  AccountHubMock.swift
//  BudClient
//
//  Created by 김민우 on 6/23/25.
//
import Foundation
import Tools


// MARK: Object
@BudServer
internal final class AccountHubMock: Sendable {
    // MARK: core
    internal static let shared = AccountHubMock()
    internal init() { }
    
    
    // MARK: state
    internal var accounts: Set<AccountMock.ID> = [
        AccountMock(email: "test@test.com", password: "123456").id
    ]
    internal func isExist(email: String, password: String) -> Bool {
        accounts.lazy
            .compactMap { $0.ref }
            .contains { $0.email == email && $0.password == password }
    }
    internal func isExist(idToken: String, accessToken: String) -> Bool {
        accounts.lazy
            .compactMap { $0.ref }
            .contains { $0.idToken == idToken && $0.accessToken == accessToken }
    }
    internal func getUserId(email: String, password: String) throws -> UserID {
        let filtered = self.accounts.lazy
            .compactMap { $0.ref }
            .filter { $0.email == email }
        
        if filtered.isEmpty { throw Error.userNotFound }
        
        guard let userId = filtered.lazy
            .first(where: { $0.password == password })?
            .userId else {
                throw Error.wrongPassword
            }
        
        return userId
    }
    internal func getUserId(googleIdToken: String, googleAccessToken: String) -> UserID? {
        accounts.lazy
            .compactMap { $0.ref }
            .first { $0.idToken == googleIdToken && $0.accessToken == googleAccessToken }?.userId
    }
    
    internal var emailTickets: Set<Ticket> = []
    internal var emailRegisterForms: [Ticket:EmailRegisterFormMock.ID] = [:]
    
    internal var googleTickets: Set<Ticket> = []
    internal var googleRegisterForms: [Ticket: GoogleRegisterFormMock.ID] = [:]
    
    
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
