//
//  EmailForm.swift
//  BudClient
//
//  Created by 김민우 on 6/23/25.
//
import Foundation


// MARK: Object
@MainActor
public final class EmailForm: Sendable {
    // MARK: core
    public init(authBoard: AuthBoard.ID) {
        self.id = ID(value: UUID())
        self.authBoard = authBoard
        
        EmailFormManager.register(self)
    }
    internal func delete() {
        EmailFormManager.unregister(self.id)
    }
    
    
    // MARK: state
    public nonisolated let id: ID
    public nonisolated let authBoard: AuthBoard.ID
    
    public var email: String = ""
    public var password: String = ""
    
    
    // MARK: action
    
    
    // MARK: value
    public struct ID: Sendable, Hashable {
        public let value: UUID
    }
    internal struct Email: Sendable, Hashable {
        internal let value: String
        
        internal init?(_ value: String) {
            guard Email.isValid(value) else { return nil }
            self.value = value
        }
        
        internal static func isValid(_ value: String) -> Bool {
            // Basic email regex for demonstration; adjust as needed
            let regex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
            return value.range(of: regex, options: .regularExpression) != nil
        }
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
