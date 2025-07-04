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
final class GoogleRegisterForm: Sendable {
    // MARK: core
    init(accountHubRef: AccountHub,
                  ticket: AccountHub.Ticket) {
        self.accountHubRef = accountHubRef
        self.ticket = ticket
        
        GoogleRegisterFormManager.register(self)
    }
    private func delete() {
        GoogleRegisterFormManager.unregister(self.id)
    }
    
    
    // MARK: state
    nonisolated let id = ID()
    nonisolated let accountHubRef: AccountHub
    nonisolated let ticket: AccountHub.Ticket
    
    var token: GoogleToken?
    
    var issue: (any Issuable)?
    
    
    // MARK: action
    func submit() async {
        // capture
        guard let token else { issue = KnownIssue(Error.tokenIsNil); return }
        guard id.isExist else { issue = KnownIssue(Error.googleRegisterFormIsDeleted); return }

        // compute
        let googleCredential = GoogleAuthProvider.credential(withIDToken: token.idToken,
                                                       accessToken: token.accessToken)
        do {
            try await Auth.auth().signIn(with: googleCredential)
        } catch {
            self.issue = UnknownIssue(error); return
        }
    }
    internal func remove() {
        accountHubRef.googleRegisterForms[ticket] = nil
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
            GoogleRegisterFormManager.container[self] != nil
        }
        var ref: GoogleRegisterForm? {
            GoogleRegisterFormManager.container[self]
        }
    }
    enum Error: String, Swift.Error {
        case tokenIsNil
        case googleRegisterFormIsDeleted
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
