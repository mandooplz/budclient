//
//  EmailForm.swift
//  BudClient
//
//  Created by 김민우 on 6/23/25.
//
import Foundation
import Tools


// MARK: Object
@MainActor
public final class EmailForm: Sendable {
    // MARK: core
    public init(authBoard: AuthBoard.ID,
                mode: SystemMode) {
        self.id = ID(value: UUID())
        self.authBoard = authBoard
        self.mode = mode
        
        EmailFormManager.register(self)
    }
    internal func delete() {
        EmailFormManager.unregister(self.id)
    }
    
    
    // MARK: state
    public nonisolated let id: ID
    public nonisolated let authBoard: AuthBoard.ID
    private nonisolated let mode: SystemMode
    
    public var email: String?
    public var password: String?
    
    public var registerForm: RegisterForm.ID?
    
    
    // MARK: action
    public func signIn() {
        fatalError()
    }
    public func setUpRegisterForm() {
        // mutate
        if self.registerForm != nil { return }
        let registerFormRef = RegisterForm(emailForm: self.id, mode: self.mode)
        self.registerForm = registerFormRef.id
    }
    
    
    // MARK: value
    public struct ID: Sendable, Hashable {
        public let value: UUID
    }
}


// MARK: Object Manager
@MainActor
public final class EmailFormManager: Sendable {
    // MARK: state
    private static var container: [EmailForm.ID: EmailForm] = [:]
    public static func register(_ object: EmailForm) {
        container[object.id] = object
    }
    public static func unregister(_ id: EmailForm.ID) {
        container[id] = nil
    }
    public static func get(_ id: EmailForm.ID) -> EmailForm? {
        container[id]
    }
}
