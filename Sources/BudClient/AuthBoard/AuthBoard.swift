//
//  AuthBoard.swift
//  BudClient
//
//  Created by 김민우 on 6/23/25.
//
import Foundation
import Values

private let logger = WorkFlow.getLogger(for: "AuthBoard")


// MARK: Object
@MainActor @Observable
public final class AuthBoard: Debuggable {
    // MARK: core
    init(tempConfig: TempConfig<BudClient.ID>) {
        self.tempConfig = tempConfig
        
        AuthBoardManager.register(self)
    }
    func delete() {
        AuthBoardManager.unregister(self.id)
    }
    
    
    // MARK: state
    public nonisolated let id = ID()
    public nonisolated let tempConfig: TempConfig<BudClient.ID>
    
    public internal(set) var signInForm: SignInForm.ID?
    
    public var issue: (any Issuable)?
    
    
    // MARK: action
    public func setUpForms() async {
        logger.start()
        
        await setUpForms(mutateHook: nil)
    }
    func setUpForms(mutateHook: Hook?) async {
        // compute
        let myConfig = tempConfig.setParent(self.id)
        
        // mutate
        await mutateHook?()
        guard id.isExist else { setIssue(Error.authBoardIsDeleted); return }
        guard signInForm == nil else {
            setIssue(Error.alreadySetUp)
            logger.failure(Error.alreadySetUp)
            return
        }
        
        let emailFormRef = SignInForm(tempConfig: myConfig)
        
        self.signInForm = emailFormRef.id
    }
    
    
    // MARK: value
    @MainActor
    public struct ID: Sendable, Hashable {
        public let value: UUID
        nonisolated init(value: UUID = UUID()) {
            self.value = value
        }
        
        var isExist: Bool {
            AuthBoardManager.container[self] != nil
        }
        public var ref: AuthBoard? {
            AuthBoardManager.container[self]
        }
    }
    public enum Error: String, Swift.Error {
        case authBoardIsDeleted
        case alreadySetUp
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
