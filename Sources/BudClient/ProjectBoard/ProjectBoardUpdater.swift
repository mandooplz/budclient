//
//  ProjectBoardUpdater.swift
//  BudClient
//
//  Created by 김민우 on 6/30/25.
//
import Foundation
import Tools
import BudServer
import Collections


// MARK: Object
@MainActor
internal final class ProjectBoardUpdater: Sendable {
    // MARK: core
    internal init(config: Config<ProjectBoard.ID>) {
        self.id = ID(value: .init())
        self.config = config
        
        ProjectBoardUpdaterManager.register(self)
    }
    internal func delete() {
        ProjectBoardUpdaterManager.unregister(self.id)
    }
    
    
    // MARK: state
    internal nonisolated let id: ID
    internal nonisolated let config: Config<ProjectBoard.ID>
   
    internal var eventQueue: Deque<ProjectHubEvent> = []
    
    
    // MARK: action
    internal func update() {
        // mutate
        guard let projectBoardRef = config.parent.ref else { return }
        let map = projectBoardRef.sourceMap
        
        while eventQueue.isEmpty == false {
            let event = eventQueue.removeFirst()
            switch event {
            case .added(let projectSource):
                if map[projectSource] != nil { return }
                let projectSourceLink = ProjectSourceLink(
                    mode: config.mode,
                    id: projectSource)
                let projectRef = Project(config: config,
                                         sourceLink: projectSourceLink)
                projectBoardRef.projects.append(projectRef.id)
                projectBoardRef.sourceMap[projectSource] = projectRef.id
            case .removed(let projectSource):
                guard let project = map[projectSource] else { return }
                
                projectBoardRef.projects.removeAll { $0 == project }
                project.ref?.delete()
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
