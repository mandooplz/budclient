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
public final class AuthBoard: Debuggable {
    // MARK: core
    internal init(tempConfig: TempConfig<BudClient.ID>) {
        self.id = ID(value: UUID())
        self.tempConfig = tempConfig
        
        AuthBoardManager.register(self)
    }
    internal func delete() {
        AuthBoardManager.unregister(self.id)
    }
    
    
    // MARK: state
    public nonisolated let id: ID
    public nonisolated let tempConfig: TempConfig<BudClient.ID>
    
    public internal(set) var signInForm: SignInForm.ID?
    public internal(set) var googleForm: GoogleForm.ID?
    
    public var issue: (any Issuable)?
    
    
    // MARK: action
    public func setUpForms() async {
        await setUpForms(beforeMutate: nil)
    }
    internal func setUpForms(beforeMutate: Hook?) async {
        // compute
        let myConfig = tempConfig.setParent(self.id)
        
        // mutate
        await beforeMutate?()
        guard id.isExist else { setIssue(Error.authBoardIsDeleted); return }
        guard signInForm == nil && googleForm == nil else { setIssue(Error.alreadySetUp); return }
        
        let emailFormRef = SignInForm(tempConfig: myConfig)
        let googleFormRef = GoogleForm(tempConfig: myConfig)
        
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
    public enum Error: String, Swift.Error {
        case authBoardIsDeleted
        case alreadySetUp
        case userIsNotSignedIn
    }
}


// MARK: Object Manager
@MainActor @Observable
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
