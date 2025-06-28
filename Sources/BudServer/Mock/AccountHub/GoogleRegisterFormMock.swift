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
package final class GoogleRegisterFormMock: Sendable {
    // MARK: core
    package init(accountHub: AccountHubMock,
                 ticket: AccountHubMock.Ticket) {
        self.id = ID(value: UUID())
        self.accountHub = accountHub
        
        GoogleRegisterFormMockManager.register(self)
    }
    internal func delete() {
        GoogleRegisterFormMockManager.unregister(self.id)
    }
    
    
    // MARK: state
    package nonisolated let id: ID
    private nonisolated let accountHub: AccountHubMock
    
    package var idToken: String?
    package var accessToken: String?
    
    package var googleUserId: String?
    
    package var issue: (any Issuable)?
    
    
    // MARK: action
    public func fetchGoogleUserId() {
        // capture
        guard let idToken else { issue = KnownIssue(Error.idTokenIsNil); return }
        guard let accessToken else { issue = KnownIssue(Error.accessTokenIsNil); return}
        
        // compute
        // idToken과 accessToken에 대해 결정론적으로 GoogleUserId가 생성된다.
        // 절대 실패하지 않는다.
        let googleUserId = GoogleUserID(idToken: idToken,
                                        accessToken: accessToken)
        
        // mutate
        self.googleUserId = googleUserId.getValue()
    }
    public func submit() {
        // signIn과 signUp이 동시에 이루어진다. 
        // 기존 계정이 있다면 생성하지 X
        // 기존 계정이 없다면 새로운 Account 객체를 생성한다. 그리고 이 Account 객체의
    }
    
    
    // MARK: value
    package struct ID: Sendable, Hashable {
        package let value: UUID
    }
    package enum Error: String, Swift.Error {
        case idTokenIsNil, accessTokenIsNil
    }
    private struct GoogleUserID: Sendable, Hashable {
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
package final class GoogleRegisterFormMockManager: Sendable {
    private static var container: [GoogleRegisterFormMock.ID: GoogleRegisterFormMock] = [:]
    package static func register(_ object: GoogleRegisterFormMock) {
        container[object.id] = object
    }
    package static func unregister(_ id: GoogleRegisterFormMock.ID) {
        container[id] = nil
    }
    package static func get(_ id: GoogleRegisterFormMock.ID) -> GoogleRegisterFormMock? {
        container[id]
    }
}

