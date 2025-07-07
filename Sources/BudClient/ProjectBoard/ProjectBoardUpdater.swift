//
//  ProjectBoardUpdater.swift
//  BudClient
//
//  Created by 김민우 on 6/30/25.
//
import Foundation
import Values
import BudServer
import Collections
import os


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
        let projectBoardRef = config.parent.ref!
        let config = self.config
        
        while queue.isEmpty == false {
            let event = queue.removeFirst()
            switch event {
            // when projectSource added
            case .added(let projectSource, let project):
                if projectBoardRef.isExist(target: project) { return }
                
                let sourceLink = ProjectSourceLink(mode: config.mode, object: projectSource)
                let projectEditorRef = ProjectEditor(config: config,
                                                     target: project,
                                                     sourceLink: sourceLink)
                
                projectBoardRef.editors.append(projectEditorRef.id)
            
            // when projectSource removed
            case .removed(let project):
                let projectEditor = projectBoardRef.editors.first { $0.ref?.target == project }
                projectEditor?.ref?.delete()
                
                projectBoardRef.editors.removeAll { $0 == projectEditor }
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
