//
//  RegisterForm.swift
//  BudClient
//
//  Created by 김민우 on 6/23/25.
//
import Foundation
import Tools
import BudServerLink


// MARK: Object
@MainActor
public final class RegisterForm: Sendable {
    // MARK: core
    public init(emailForm: EmailForm.ID,
                mode: SystemMode) {
        self.id = ID(value: UUID())
        self.emailForm = emailForm
        self.mode = mode
        
        RegisterFormManager.register(self)
    }
    internal func delete() {
        RegisterFormManager.unregister(self.id)
    }
    
    
    // MARK: state
    public nonisolated let id: ID
    public nonisolated let emailForm: EmailForm.ID
    private nonisolated let mode: SystemMode
    
    public var email: String?
    public var password: String?
    public var passwordCheck: String?
    
    
    // MARK: action
    public func registerAndSignIn() {
        // 이를 구현하려면 BudServer가 필요하다.
        let budServerLink = try! BudServer(mode: self.mode)
        
        fatalError()
    }
    
    
    // MARK: value
    public struct ID: Sendable, Hashable {
        public let value: UUID
    }
}

// MARK: Object Manager
@MainActor
public final class RegisterFormManager: Sendable {
    // MARK: state
    private static var container: [RegisterForm.ID: RegisterForm] = [:]
    public static func register(_ object: RegisterForm) {
        container[object.id] = object
    }
    public static func unregister(_ id: RegisterForm.ID) {
        container[id] = nil
    }
    public static func get(_ id: RegisterForm.ID) -> RegisterForm? {
        container[id]
    }
}
