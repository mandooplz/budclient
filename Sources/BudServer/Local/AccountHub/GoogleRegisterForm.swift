//
//  GoogleRegisterForm.swift
//  BudClient
//
//  Created by 김민우 on 6/29/25.
//
import Foundation
import Values
import FirebaseAuth

private let logger = WorkFlow.getLogger(for: "GoogleRegisterForm")


// MARK: Object
@MainActor
package final class GoogleRegisterForm: GoogleRegisterFormInterface {
    // MARK: core
    package init(accountHub: AccountHub.ID,
                  ticket: CreateFormTicket) {
        self.accountHub = accountHub
        self.ticket = ticket
        
        GoogleRegisterFormManager.register(self)
    }
    func delete() {
        GoogleRegisterFormManager.unregister(self.id)
    }
    
    
    // MARK: state
    package nonisolated let id = ID()
    nonisolated let accountHub: AccountHub.ID
    nonisolated let ticket: CreateFormTicket
    
    private var token: GoogleToken?
    package func setToken(_ token: GoogleToken) async {
        self.token = token
    }
    
    
    // MARK: action
    package func submit() async throws {
        logger.start()
        
        // capture
        guard let token else { throw Error.tokenIsNil }
        guard id.isExist else { throw Error.googleRegisterFormIsDeleted }

        // compute
        let googleCredential = GoogleAuthProvider.credential(withIDToken: token.idToken,
                                                       accessToken: token.accessToken)
        try await Auth.auth().signIn(with: googleCredential)
    }
    package func remove() {
        logger.start()
        
        accountHub.ref?.googleRegisterForms[ticket] = nil
        self.delete()
    }
    
    
    // MARK: value
    @MainActor
    package struct ID: GoogleRegisterFormIdentity {
        let value = UUID()
        nonisolated init() { }
        
        package var isExist: Bool {
            GoogleRegisterFormManager.container[self] != nil
        }
        package var ref: GoogleRegisterForm? {
            GoogleRegisterFormManager.container[self]
        }
    }
    package enum Error: String, Swift.Error {
        case tokenIsNil
        case googleRegisterFormIsDeleted
    }
}


// MARK: Object Manager
@MainActor
fileprivate final class GoogleRegisterFormManager: Sendable {
    // MARK: state
    fileprivate static var container: [GoogleRegisterForm.ID: GoogleRegisterForm] = [:]
    fileprivate static func register(_ object: GoogleRegisterForm) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: GoogleRegisterForm.ID) {
        container[id] = nil
    }
}
