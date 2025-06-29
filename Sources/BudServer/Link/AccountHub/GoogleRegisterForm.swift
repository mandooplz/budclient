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
    internal struct ID: Sendable, Hashable {
        package let value: UUID
    }
    internal enum Error: String, Swift.Error {
        case idTokenIsNil, accessTokenIsNil
        case googleUserIdIsNil
    }
}


// MARK: Object Manager
@Server
internal final class GoogleRegisterFormManager: Sendable {
    // MARK: state
    private static var container: [GoogleRegisterForm.ID: GoogleRegisterForm] = [:]
    internal static func register(_ object: GoogleRegisterForm) {
        container[object.id] = object
    }
    internal static func unregister(_ id: GoogleRegisterForm.ID) {
        container[id] = nil
    }
    internal static func get(_ id: GoogleRegisterForm.ID) -> GoogleRegisterForm? {
        container[id]
    }
}
