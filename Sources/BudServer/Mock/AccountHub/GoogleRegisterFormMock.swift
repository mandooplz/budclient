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
final class GoogleRegisterFormMock: Sendable {
    // MARK: core
    init(accountHub: AccountHubMock,
                  ticket: AccountHubMock.Ticket) {
        self.ticket = ticket
        self.accountHub = accountHub
        
        GoogleRegisterFormMockManager.register(self)
    }
    func delete() {
        GoogleRegisterFormMockManager.unregister(self.id)
    }
    
    
    // MARK: state
    nonisolated let id = ID()
    private nonisolated let ticket: AccountHubMock.Ticket
    private nonisolated let accountHub: AccountHubMock
    
    var token: GoogleToken?
    
    var issue: (any Issuable)?
    
    
    // MARK: action
    func submit() {
        // capture
        guard let token else { issue = KnownIssue(Error.tokenIsNil); return }
        if accountHub.isExist(token: token) == true { return }
        
        // mutate
        let accountRef = AccountMock(token: token)
        accountHub.accounts.insert(accountRef.id)
    }
    func remove() {
        // mutate
        accountHub.googleRegisterForms[ticket] = nil
        self.delete()
    }
    
    
    // MARK: value
    @Server
    struct ID: Sendable, Hashable {
        let value: UUID
        nonisolated init(value: UUID = UUID()) {
            self.value = value
        }
        
        var isExist: Bool {
            GoogleRegisterFormMockManager.container[self] != nil
        }
        var ref: GoogleRegisterFormMock? {
            GoogleRegisterFormMockManager.container[self]
        }
    }
    enum Error: String, Swift.Error {
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

