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
    
    public internal(set) var emailForm: EmailForm.ID?
    public internal(set) var googleForm: GoogleForm.ID?
    
    public var issue: (any Issuable)?
    public var isIssueOccurred: Bool { self.issue != nil }
    
    
    // MARK: action
    public func setUpForms() {
        // mutate
        guard emailForm == nil && googleForm == nil else { return }
        
        let emailFormRef = EmailForm(authBoard: id, mode: mode)
        let googleFormRef = GoogleForm(authBoard: id, mode: mode)
        
        self.emailForm = emailFormRef.id
        self.googleForm = googleFormRef.id
    }
    
    
    
    // MARK: value
    public struct ID: Sendable, Hashable {
        public let value: UUID
    }
    public typealias UserID = String
    public enum Error: String, Swift.Error {
        case userIsNotSignedIn
    }
}


// MARK: Object Manager
@MainActor
public final class AuthBoardManager {
    // MARK: state
    private static var container: [AuthBoard.ID: AuthBoard] = [:]
    internal static func register(_ object: AuthBoard) {
        container[object.id] = object
    }
    internal static func unregister(_ id: AuthBoard.ID) {
        container[id] = nil
    }
    public static func get(_ id: AuthBoard.ID) -> AuthBoard? {
        container[id]
    }
}
