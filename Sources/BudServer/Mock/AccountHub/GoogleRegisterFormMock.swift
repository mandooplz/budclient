//
//  GoogleFormMock.swift
//  BudClient
//
//  Created by 김민우 on 6/29/25.
//
import Foundation
import Tools
import CryptoKit


// MARK: Object
@MainActor
internal final class GoogleRegisterFormMock: Sendable {
    // MARK: core
    internal init(accountHub: AccountHubMock,
                 ticket: AccountHubMock.Ticket) {
        self.id = ID(value: UUID())
        self.accountHub = accountHub
        
        GoogleRegisterFormMockManager.register(self)
    }
    internal func delete() {
        GoogleRegisterFormMockManager.unregister(self.id)
    }
    
    
    // MARK: state
    internal nonisolated let id: ID
    private nonisolated let accountHub: AccountHubMock
    
    internal var idToken: String?
    internal var accessToken: String?
    
    internal var issue: (any Issuable)?
    
    
    // MARK: action
    internal func submit() {
        // capture
        guard let idToken else { issue = KnownIssue(Error.idTokenIsNil); return }
        guard let accessToken else { issue = KnownIssue(Error.accessTokenIsNil); return}
        if accountHub.isExist(idToken: idToken, accessToken: accessToken) == true { return }
        
        // mutate
        let accountRef = AccountMock(idToken: idToken, accessToken: accessToken)
        accountHub.accounts.insert(accountRef.id)
    }
    
    
    // MARK: value
    internal struct ID: Sendable, Hashable {
        let value: UUID
    }
    internal enum Error: String, Swift.Error {
        case idTokenIsNil, accessTokenIsNil
        case googleUserIdIsNil
    }
    internal struct GoogleUserID: Sendable, Hashable {
        let idToken: String
        let accessToken: String
        
        func getValue() -> String {
            let combined = idToken + ":" + accessToken
            
            // SHA256 해시를 사용한 결정론적 user id 생성
            let data = combined.data(using: .utf8)!
            let hash = SHA256.hash(data: data)
            return hash.compactMap { String(format: "%02x", $0) }.joined()
        }
    }
}


// MARK: Object Manager
@MainActor
internal final class GoogleRegisterFormMockManager: Sendable {
    private static var container: [GoogleRegisterFormMock.ID: GoogleRegisterFormMock] = [:]
    internal static func register(_ object: GoogleRegisterFormMock) {
        container[object.id] = object
    }
    internal static func unregister(_ id: GoogleRegisterFormMock.ID) {
        container[id] = nil
    }
    internal static func get(_ id: GoogleRegisterFormMock.ID) -> GoogleRegisterFormMock? {
        container[id]
    }
}

