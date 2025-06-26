//
//  Project.swift
//  BudClient
//
//  Created by 김민우 on 6/25/25.
//

import Foundation

// MARK: Object
@MainActor @Observable 
public final class Project: Sendable {
    // MARK: core
    public init(userId: String) {
        self.id = ID(value: .init())
        self.userId = userId
        
        ProjectManager.register(self)
    }
    public func delete() {
        ProjectManager.unregister(self.id)
    }
    
    
    // MARK: state
    public nonisolated let id: ID
    public nonisolated let userId: String
    
    
    // MARK: action
    
    
    // MARK: value
    public struct ID: Sendable, Hashable {
        public let value: UUID
    }
}

// MARK: Object Manager
@MainActor
public final class ProjectManager: Sendable {
    // MARK: state
    private static var container: [Project.ID: Project] = [:]
    public static func register(_ object: Project) {
        container[object.id] = object
    }
    public static func unregister(_ id: Project.ID) {
        container[id] = nil
    }
    public static func get(_ id: Project.ID) -> Project? {
        container[id]
    }
}
