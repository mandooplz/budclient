//
//  AuthBoard.swift
//  BudClient
//
//  Created by 김민우 on 6/23/25.
//
import Foundation


// MARK: Object
@MainActor
public final class AuthBoard {
    // MARK: core
    public init(budClient: BudClient.ID) {
        self.id = ID(value: UUID())
        self.budClient = budClient
        
        AuthBoardManager.register(self)
    }
    internal func delete() {
        AuthBoardManager.unregister(self.id)
    }
    
    
    // MARK: state
    public nonisolated let id: ID
    public nonisolated let budClient: BudClient.ID
    
    public var emailForm: EmailForm.ID?
    
    
    // MARK: action
    public func setUpEmailForm() {
        // mutate
        let emailFormRef = EmailForm(authBoard: self.id)
        self.emailForm = emailFormRef.id
    }
    
    
    // MARK: value
    public struct ID: Sendable, Hashable {
        public let value: UUID
    }
    public struct UserID: Sendable, Hashable {
        public let value: String
    }
}


// MARK: Object Manager
@MainActor
public final class AuthBoardManager {
    // MARK: state
    private static var container: [AuthBoard.ID: AuthBoard] = [:]
    public static func register(_ object: AuthBoard) {
        container[object.id] = object
    }
    public static func unregister(_ id: AuthBoard.ID) {
        container[id] = nil
    }
    public static func get(_ id: AuthBoard.ID) -> AuthBoard? {
        container[id]
    }
}
