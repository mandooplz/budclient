//
//  GoogleRegisterForm.swift
//  BudClient
//
//  Created by 김민우 on 6/29/25.
//
import Foundation
import Tools
import FirebaseAuth


// MARK: Object
@Server
internal final class GoogleRegisterForm: Sendable {
    // MARK: core
    internal init(accountHubRef: AccountHub,
                  ticket: AccountHub.Ticket) {
        self.id = ID(value: .init())
        self.accountHubRef = accountHubRef
        self.ticket = ticket
        
        GoogleRegisterFormManager.register(self)
    }
    private func delete() {
        GoogleRegisterFormManager.unregister(self.id)
    }
    
    
    // MARK: state
    internal nonisolated let id: ID
    internal nonisolated let accountHubRef: AccountHub
    internal nonisolated let ticket: AccountHub.Ticket
    
    internal var idToken: String?
    internal var accessToken: String?
    
    internal var issue: (any Issuable)?
    
    
    // MARK: action
    internal func submit() async {
        // capture
        guard let idToken else { issue = KnownIssue(Error.idTokenIsNil); return }
        guard let accessToken else { issue = KnownIssue(Error.accessTokenIsNil); return}
        
        // compute
        let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                       accessToken: accessToken)
        do {
            try await Auth.auth().signIn(with: credential)
        } catch {
            self.issue = UnknownIssue(error)
            return
        }
    }
    internal func remove() {
        accountHubRef.googleRegisterForms[ticket] = nil
        self.delete()
    }
    
    
    // MARK: value
    @Server
    internal struct ID: Sendable, Hashable {
        internal let value: UUID
        
        internal var isExist: Bool {
            GoogleRegisterFormManager.container[self] != nil
        }
        internal var ref: GoogleRegisterForm? {
            GoogleRegisterFormManager.container[self]
        }
    }
    internal enum Error: String, Swift.Error {
        case idTokenIsNil, accessTokenIsNil
        case googleUserIdIsNil
    }
}


// MARK: Object Manager
@Server
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
