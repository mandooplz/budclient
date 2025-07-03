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
@MainActor @Observable
internal final class ProjectBoardUpdater: Debuggable {
    // MARK: core
    init(config: Config<ProjectBoard.ID>) {
        self.id = ID(value: .init())
        self.config = config
        
        ProjectBoardUpdaterManager.register(self)
    }
    func delete() {
        ProjectBoardUpdaterManager.unregister(self.id)
    }
    
    
    // MARK: state
    nonisolated let id: ID
    nonisolated let config: Config<ProjectBoard.ID>
   
    var eventQueue: Deque<ProjectHubEvent> = []
    
    var issue: (any Issuable)?
    
    
    // MARK: action
    func update() async {
        await update(mutateHook: nil)
    }
    func update(mutateHook: Hook?) async {
        // mutate
        await mutateHook?()
        guard let projectBoardRef = config.parent.ref else { return }
        guard id.isExist else { setIssue(Error.updaterIsDeleted); return }
        let map = projectBoardRef.projectSourceMap
        
        while eventQueue.isEmpty == false {
            let event = eventQueue.removeFirst()
            switch event {
            case .added(let projectSource):
                if map[projectSource] != nil {
                    setIssue(Error.alreadyAdded)
                    return
                }
                let projectSourceLink = ProjectSourceLink(
                    mode: config.mode,
                    id: projectSource)
                let projectRef = Project(config: config,
                                         sourceLink: projectSourceLink)
                projectBoardRef.projects.append(projectRef.id)
                projectBoardRef.projectSourceMap[projectSource] = projectRef.id
            case .removed(let projectSource):
                guard let project = map[projectSource] else {
                    setIssue(Error.alreadyRemoved)
                    return
                }
                
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
    internal enum Error: String, Swift.Error {
        case updaterIsDeleted
        case alreadyAdded, alreadyRemoved
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
