//
//  Project.swift
//  BudClient
//
//  Created by 김민우 on 6/25/25.
//
import Foundation
import Tools


// MARK: Object
@MainActor @Observable
public final class Project: Sendable {
    // MARK: core
    public init(mode: SystemMode, projectBoard: ProjectBoard.ID, userId: String) {
        self.id = ID(value: .init())
        self.mode = mode
        self.projectBoard = projectBoard
        self.userId = userId
        
        ProjectManager.register(self)
    }
    public func delete() {
        ProjectManager.unregister(self.id)
    }
    
    
    // MARK: state
    public nonisolated let id: ID
    internal nonisolated let mode: SystemMode
    public nonisolated let userId: String
    internal nonisolated let projectBoard: ProjectBoard.ID
    
    public var name: String = "UnknownProject"
    
    
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
