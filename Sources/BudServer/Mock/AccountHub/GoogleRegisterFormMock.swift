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
package final class GoogleRegisterFormMock: GoogleRegisterFormInterface {
    // MARK: core
    init(accountHub: AccountHubMock.ID,
         ticket: CreateFormTicket) {
        self.ticket = ticket
        self.accountHub = accountHub
        
        GoogleRegisterFormMockManager.register(self)
    }
    func delete() {
        GoogleRegisterFormMockManager.unregister(self.id)
    }
    
    
    // MARK: state
    package nonisolated let id = ID()
    nonisolated let ticket: CreateFormTicket
    nonisolated let accountHub: AccountHubMock.ID
    
    private var token: GoogleToken?
    package func setToken(_ token: GoogleToken) async {
        self.token = token
    }
    
    
    // MARK: action
    package func submit() throws {
        // capture
        guard let token else { throw Error.tokenIsNil }
        guard let accountHubRef = accountHub.ref else { return }
        guard accountHubRef.isExist(token: token) == false else { return }
        
        // mutate
        let accountRef = AccountMock(token: token)
        accountHubRef.accounts.insert(accountRef.id)
    }
    package func remove() {
        // mutate
        accountHub.ref?.googleRegisterForms[ticket] = nil
        self.delete()
    }
    
    
    // MARK: value
    @Server
    package struct ID: GoogleRegisterFormIdentity {
        let value: UUID = UUID()
        nonisolated init() { }
        
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

