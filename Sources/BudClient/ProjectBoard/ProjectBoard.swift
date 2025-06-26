//
//  ProjectBoard.swift
//  BudClient
//
//  Created by 김민우 on 6/25/25.
//
import Foundation


// MARK: Object
@MainActor @Observable
public final class ProjectBoard: Sendable {
    // MARK: core
    init(userId: String) {
        self.id = ID(value: .init())
        self.userId = userId
        
        ProjectBoardManager.register(self)
    }
    internal func delete() {
        ProjectBoardManager.unregister(self.id)
    }
    
    
    // MARK: state
    public nonisolated let id: ID
    public nonisolated let userId: String
    
    public internal(set) var projects: [Project.ID] = []
    
    
    // MARK: action
    public func fetchProjects() async {
        // BudServer.ProjectHub에 있는 나의 모든 서버를 가져온다. 
    }
    
    
    // MARK: value
    public struct ID: Sendable, Hashable {
        public let value: UUID
    }
}


// MARK: Object Manager
@MainActor
public final class ProjectBoardManager: Sendable {
    // MARK: state
    private static var container: [ProjectBoard.ID: ProjectBoard] = [:]
    public static func register(_ object: ProjectBoard) {
        container[object.id] = object
    }
    public static func unregister(_ id: ProjectBoard.ID) {
        container[id] = nil
    }
    public static func get(_ id: ProjectBoard.ID) -> ProjectBoard? {
        container[id]
    }
}

