//
//  AuthBoard.swift
//  BudClient
//
//  Created by 김민우 on 6/23/25.
//
import Foundation
import Tools


// MARK: Object
@MainActor @Observable
public final class AuthBoard {
    // MARK: core
    internal init(budClient: BudClient.ID,
                mode: SystemMode) {
        self.id = ID(value: UUID())
        self.budClient = budClient
        self.mode = mode
        
        AuthBoardManager.register(self)
    }
    internal func delete() {
        AuthBoardManager.unregister(self.id)
    }
    
    
    // MARK: state
    public nonisolated let id: ID
    public nonisolated let budClient: BudClient.ID
    private nonisolated let mode: SystemMode
    
    public internal(set) var signInForm: SignInForm.ID?
    public internal(set) var googleForm: GoogleForm.ID?
    
    public var issue: (any Issuable)?
    
    
    // MARK: action
    public func setUpForms() async {
        await setUpForms(beforeMutate: nil)
    }
    internal func setUpForms(beforeMutate: Hook?) async {
        // mutate
        await beforeMutate?()
        guard id.isExist else { return }
        guard signInForm == nil && googleForm == nil else { return }
        
        let emailFormRef = SignInForm(authBoard: id, mode: mode)
        let googleFormRef = GoogleForm(authBoard: id, mode: mode)
        
        self.signInForm = emailFormRef.id
        self.googleForm = googleFormRef.id
    }
    
    
    // MARK: value
    @MainActor
    public struct ID: Sendable, Hashable {
        public let value: UUID
        
        internal var isExist: Bool {
            AuthBoardManager.container[self] != nil
        }
        public var ref: AuthBoard? {
            AuthBoardManager.container[self]
        }
    }
    public typealias UserID = String
    public enum Error: String, Swift.Error {
        case userIsNotSignedIn
    }
}


// MARK: Object Manager
@MainActor
fileprivate final class AuthBoardManager {
    // MARK: state
    fileprivate static var container: [AuthBoard.ID: AuthBoard] = [:]
    fileprivate static func register(_ object: AuthBoard) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: AuthBoard.ID) {
        container[id] = nil
    }
}
