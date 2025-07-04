//
//  GoogleFormMock.swift
//  BudClient
//
//  Created by 김민우 on 6/29/25.
//
import Foundation
import Tools


// MARK: Object
@Server
package final class GoogleRegisterFormMock: Sendable {
    // MARK: core
    package init(accountHub: AccountHubMock,
                  ticket: AccountHubMock.Ticket) {
        self.ticket = ticket
        self.accountHub = accountHub
        
        GoogleRegisterFormMockManager.register(self)
    }
    package func delete() {
        GoogleRegisterFormMockManager.unregister(self.id)
    }
    
    
    // MARK: state
    package nonisolated let id = ID()
    private nonisolated let ticket: AccountHubMock.Ticket
    private nonisolated let accountHub: AccountHubMock
    
    package var token: GoogleToken?
    
    package var issue: (any Issuable)?
    
    
    // MARK: action
    package func submit() {
        // capture
        guard let token else { issue = KnownIssue(Error.tokenIsNil); return }
        if accountHub.isExist(token: token) == true { return }
        
        // mutate
        let accountRef = AccountMock(token: token)
        accountHub.accounts.insert(accountRef.id)
    }
    package func remove() {
        // mutate
        accountHub.googleRegisterForms[ticket] = nil
        self.delete()
    }
    
    
    // MARK: value
    @Server
    package struct ID: Sendable, Hashable {
        package let value: UUID
        package nonisolated init(value: UUID = UUID()) {
            self.value = value
        }
        
        package var isExist: Bool {
            GoogleRegisterFormMockManager.container[self] != nil
        }
        package var ref: GoogleRegisterFormMock? {
            GoogleRegisterFormMockManager.container[self]
        }
    }
    package enum Error: String, Swift.Error {
        case tokenIsNil
        case googleUserIdIsNil
    }
}


// MARK: Object Manager
@Server
fileprivate final class GoogleRegisterFormMockManager: Sendable {
    fileprivate static var container: [GoogleRegisterFormMock.ID: GoogleRegisterFormMock] = [:]
    fileprivate static func register(_ object: GoogleRegisterFormMock) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: GoogleRegisterFormMock.ID) {
        container[id] = nil
    }
}

