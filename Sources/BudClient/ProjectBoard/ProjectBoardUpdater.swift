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
        self.config = config
        
        ProjectBoardUpdaterManager.register(self)
    }
    func delete() {
        ProjectBoardUpdaterManager.unregister(self.id)
    }
    
    
    // MARK: state
    public nonisolated let id = ID()
    public nonisolated let config: Config<ProjectBoard.ID>
   
    var queue: Deque<ProjectHubEvent> = []
    
    public var issue: (any Issuable)?
    
    
    // MARK: action
    func update() async {
        await update(mutateHook: nil)
    }
    func update(mutateHook: Hook?) async {
        // mutate
        await mutateHook?()
        guard id.isExist else { setIssue(Error.updaterIsDeleted); return }
        let projectHubLink = await config.budServerLink.getProjectHub()
        let projectBoardRef = config.parent.ref!
        let config = self.config
        let map = projectBoardRef.projectSourceMap
        
        while queue.isEmpty == false {
            let event = queue.removeFirst()
            switch event {
            // when projectSource added
            case .added(let project):
                if map[project] != nil {
                    setIssue(Error.alreadyAdded)
                    return
                }
                
                
                guard let projectSourceLink = await projectHubLink.getProjectSource(project) else {
                    setIssue(Error.projectSourceDoesNotExist)
                    return
                }
                let projectRef = Project(config: config,
                                         target: project,
                                         sourceLink: projectSourceLink)
                
                projectBoardRef.projects.append(projectRef.id)
                projectBoardRef.projectSourceMap[project] = projectRef.id
            
            // when projectSource removed
            case .removed(let projectSource):
                guard let project = map[projectSource] else {
                    setIssue(Error.alreadyRemoved)
                    return
                }
                
                projectBoardRef.projects.removeAll { $0 == project }
                projectBoardRef.projectSourceMap[projectSource] = nil
                project.ref?.delete()
            }
        }
    }
    
    
    // MARK: value
    @MainActor
    public struct ID: Sendable, Hashable {
        public let value: UUID
        nonisolated init(value: UUID = UUID()) {
            self.value = value
        }
        
        var isExist: Bool {
            ProjectBoardUpdaterManager.container[self] != nil
        }
        public var ref: ProjectBoardUpdater? {
            ProjectBoardUpdaterManager.container[self]
        }
    }
    public enum Error: String, Swift.Error {
        case updaterIsDeleted
        case alreadyAdded, alreadyRemoved
        case projectSourceDoesNotExist
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
