//
//  GoogleRegisterForm.swift
//  BudClient
//
//  Created by 김민우 on 6/29/25.
//
import Foundation
import Values
import FirebaseAuth


// MARK: Object
@Server
package final class GoogleRegisterForm: Sendable {
    // MARK: core
    private typealias Manager = GoogleRegisterFormManager
    package init(accountHubRef: AccountHub,
                  ticket: CreateGoogleForm) {
        self.accountHubRef = accountHubRef
        self.ticket = ticket
        
        GoogleRegisterFormManager.register(self)
    }
    private func delete() {
        GoogleRegisterFormManager.unregister(self.id)
    }
    
    
    // MARK: state
    package nonisolated let id = GoogleRegisterFormID()
    package nonisolated let accountHubRef: AccountHub
    package nonisolated let ticket: CreateGoogleForm
    
    package var token: GoogleToken?
    
    package var issue: (any Issuable)?
    
    
    // MARK: action
    package func submit() async {
        // capture
        guard let token else { issue = KnownIssue(Error.tokenIsNil); return }
        guard Manager.isExist(id) else { issue = KnownIssue(Error.googleRegisterFormIsDeleted); return }

        // compute
        let googleCredential = GoogleAuthProvider.credential(withIDToken: token.idToken,
                                                       accessToken: token.accessToken)
        do {
            try await Auth.auth().signIn(with: googleCredential)
        } catch {
            self.issue = UnknownIssue(error); return
        }
    }
    package func remove() {
        accountHubRef.googleRegisterForms[ticket] = nil
        self.delete()
    }
    
    
    // MARK: value
    package enum Error: String, Swift.Error {
        case tokenIsNil
        case googleRegisterFormIsDeleted
    }
}


// MARK: Object Manager
@Server
package final class GoogleRegisterFormManager: Sendable {
    // MARK: state
    fileprivate static var container: [GoogleRegisterFormID: GoogleRegisterForm] = [:]
    fileprivate static func register(_ object: GoogleRegisterForm) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: GoogleRegisterFormID) {
        container[id] = nil
    }
    package static func get(_ id: GoogleRegisterFormID) -> GoogleRegisterForm? {
        container[id]
    }
    package static func isExist(_ id: GoogleRegisterFormID) -> Bool {
        container[id] != nil
    }
}
