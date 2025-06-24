//
//  AccountHub.swift
//  BudClient
//
//  Created by 김민우 on 6/23/25.
//
import Foundation
import Tools


// MARK: Object
@MainActor
public final class AccountHubMock: Sendable {
    // MARK: core
    public static let shared = AccountHubMock()
    private init() { }
    
    
    // MARK: state
    public var accounts: Set<Account.ID> = []
    public func isExist(email: String, password: String) -> Bool {
        // capture
        let accounts = self.accounts
        
        // compute
        let isExist = accounts.lazy
            .compactMap { AccountManager.get($0) }
            .contains { $0.email == email && $0.password == password }
        return isExist
    }
    public func getUserId(email: String, password: String) throws -> Account.UserID {
        let filtered = self.accounts.lazy
            .compactMap { AccountManager.get($0) }
            .filter { $0.email == email }
        
        if filtered.isEmpty { throw Error.userNotFound }
        
        guard let userId = filtered.lazy
            .first(where: { $0.password == password })?
            .userId else {
                throw Error.wrongPassword
            }
        
        return userId
    }
    
    public var tickets: Set<Ticket> = []
    public var registerForms: [Ticket:RegisterFormMock.ID] = [:]
    
    
    // MARK: action
    public func generateForms() {
        // mutate
        for ticket in tickets {
            let registerFormRef = RegisterFormMock(accountHub: self,
                                                   ticket: ticket)
            self.registerForms[ticket] = registerFormRef.id
            tickets.remove(ticket)
        }
    }
    
    
    // MARK: value
    public struct Ticket: Sendable, Hashable {
        public let value: UUID
        
        public init(value: UUID = UUID()) {
            self.value = value
        }
    }
    public enum Error: String, Swift.Error {
        case userNotFound, wrongPassword
    }
}
