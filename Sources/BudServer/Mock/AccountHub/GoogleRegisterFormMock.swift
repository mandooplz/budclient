//
//  GoogleFormMock.swift
//  BudClient
//
//  Created by 김민우 on 6/29/25.
//
import Foundation
import Values


// MARK: Object
@Server
package final class GoogleRegisterFormMock: Sendable {
    // MARK: core
    package init(accountHub: AccountHubMock,
                  ticket: CreateGoogleForm) {
        self.ticket = ticket
        self.accountHub = accountHub
        
        GoogleRegisterFormMockManager.register(self)
    }
    package func delete() {
        GoogleRegisterFormMockManager.unregister(self.id)
    }
    
    
    // MARK: state
    package nonisolated let id = GoogleRegisterFormID()
    private nonisolated let ticket: CreateGoogleForm
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
    package enum Error: String, Swift.Error {
        case tokenIsNil
        case googleUserIdIsNil
    }
}


// MARK: Object Manager
@Server
package final class GoogleRegisterFormMockManager: Sendable {
    fileprivate static var container: [GoogleRegisterFormID: GoogleRegisterFormMock] = [:]
    fileprivate static func register(_ object: GoogleRegisterFormMock) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: GoogleRegisterFormID) {
        container[id] = nil
    }
    package static func get(_ id: GoogleRegisterFormID) -> GoogleRegisterFormMock? {
        container[id]
    }
    package static func isExist(_ id: GoogleRegisterFormID) -> Bool {
        container[id] != nil
    }
}

