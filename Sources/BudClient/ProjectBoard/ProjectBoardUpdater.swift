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
public final class ProjectBoardUpdater: Debuggable {
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
    public nonisolated let id: ID
    public nonisolated let config: Config<ProjectBoard.ID>
   
    var eventQueue: Deque<ProjectHubEvent> = []
    
    public var issue: (any Issuable)?
    
    
    // MARK: action
    func update() async {
        await update(mutateHook: nil)
    }
    func update(mutateHook: Hook?) async {
        // mutate
        await mutateHook?()
        guard id.isExist else { setIssue(Error.updaterIsDeleted); return }
        let projectBoardRef = config.parent.ref!
        let map = projectBoardRef.projectSourceMap
        
        while eventQueue.isEmpty == false {
            let event = eventQueue.removeFirst()
            switch event {
            // when projectSource added
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
            
            // when projectSource removed
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
    public struct ID: Sendable, Hashable {
        public let value: UUID
        var isExist: Bool {
            ProjectBoardUpdaterManager.container[self] != nil
        }
        public var ref: ProjectBoardUpdater? {
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
