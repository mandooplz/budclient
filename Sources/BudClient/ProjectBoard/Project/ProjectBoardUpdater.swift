//
//  ProjectBoardUpdater.swift
//  BudClient
//
//  Created by 김민우 on 6/30/25.
//
import Foundation
import Tools


// MARK: Object
@MainActor
internal final class ProjectBoardUpdater: Sendable {
    // MARK: core
    internal init(mode: SystemMode, projectBoard: ProjectBoard.ID) {
        self.id = ID(value: .init())
        self.mode = mode
        self.projectBoard = projectBoard
        
        ProjectBoardUpdaterManager.register(self)
    }
    internal func delete() {
        ProjectBoardUpdaterManager.unregister(self.id)
    }
    
    
    // MARK: state
    internal nonisolated let id: ID
    private nonisolated let mode: SystemMode
    internal nonisolated let projectBoard: ProjectBoard.ID
    
    internal var diffs: Set<Diff> = []
    
    
    // MARK: action
    internal func update() {
        // capture
        
        
        // mutate
        guard let projectBoardRef = projectBoard.ref else { return }
        let map = projectBoardRef.projectSourceMap
        let userId = projectBoardRef.userId
        for diff in diffs {
            switch diff {
            case .added(let projectSource):
                if map[projectSource] != nil { return }
                let projectRef = Project(mode: mode,
                                         projectBoard: projectBoard,
                                         userId: userId,
                                         source: projectSource)
                projectBoardRef.projects.append(projectRef.id)
            case .removed(let projectSource):
                if map[projectSource] == nil { return }
                fatalError()
            }
        }
    }
    
    
    // MARK: value
    @MainActor
    internal struct ID: Sendable, Hashable {
        let value: UUID
        var isExist: Bool {
            ProjectBoardUpdaterManager.container[self] != nil
        }
        var ref: ProjectBoardUpdater? {
            ProjectBoardUpdaterManager.container[self]
        }
    }
    internal enum Diff: Sendable, Hashable {
        case added(projectSource: String)
        case removed(projectSource: String)
    }
}


// MARK: Object Manager
@MainActor @Observable
fileprivate final class ProjectBoardUpdaterManager: Sendable {
    fileprivate static var container: [ProjectBoardUpdater.ID: ProjectBoardUpdater] = [:]
    fileprivate static func register(_ object: ProjectBoardUpdater) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: ProjectBoardUpdater.ID) {
        container[id] = nil
    }
}
