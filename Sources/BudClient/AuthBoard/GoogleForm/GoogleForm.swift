//
//  GoogleForm.swift
//  BudClient
//
//  Created by 김민우 on 6/28/25.
//
import Foundation
import Tools
import BudCache
import BudServer


// MARK: Object
@MainActor @Observable
public final class GoogleForm: Sendable {
    // MARK: core
    internal init(authBoard: AuthBoard.ID,
                  mode: SystemMode) {
        self.id = ID(value: UUID())
        self.mode = mode
        self.authBoard = authBoard
        
        GoogleFormManager.register(self)
    }
    internal func delete() {
        GoogleFormManager.unregister(self.id)
    }
    
    
    // MARK: state
    public nonisolated let id: ID
    public nonisolated let authBoard: AuthBoard.ID
    internal nonisolated let mode: SystemMode
    
    public var idToken: String?
    public var accessToken: String?
    
    public var issue: (any Issuable)?
    
    
    // MARK: action
    public func signIn() {
        // capture
        guard let idToken else { issue = KnownIssue(Error.idTokenIsNil); return }
        guard let accessToken else { issue = KnownIssue(Error.accessTokenIsNil); return }
        
        
        // compute
        // 이 안에서 이루어져야 하는 작업은?
        // idToken과 accessToken을 사용해 로그인 처리한다.
//        let googleCredential = GoogleAuthProvider.credential(withIDToken: idToken,
//                                                             accessToken: accessToken)
//        
//        let result = Auth.auth().signIn(with: googleCredential)

        
        // mutate
        print(idToken, accessToken)
        // EmailForm, SignUpForm에서처럼
    }
    
    
    // MARK: value
    public struct ID: Sendable, Hashable {
        public let value: UUID
    }
    public enum Error: String, Swift.Error {
        case idTokenIsNil, accessTokenIsNil
    }
}


// MARK: Object Manager
@MainActor
public final class GoogleFormManager: Sendable {
    // MARK: state
    private static var container: [GoogleForm.ID: GoogleForm] = [:]
    internal static func register(_ object: GoogleForm) {
        container[object.id] = object
    }
    internal static func unregister(_ id: GoogleForm.ID) {
        container[id] = nil
    }
    public static func get(_ id: GoogleForm.ID) -> GoogleForm? {
        container[id]
    }
}
