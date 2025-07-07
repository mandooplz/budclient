//
//  ProjectUpdater.swift
//  BudClient
//
//  Created by 김민우 on 7/3/25.
//
import Foundation
import Values
import Collections
import BudServer


// MARK: Object
@MainActor
final class ProjectUpdater: Debuggable {
    // MARK: core
    init(config: Config<ProjectEditor.ID>) {
        self.config = config
        
        ProjectUpdaterManager.register(self)
    }
    func delete() {
        ProjectUpdaterManager.unregister(self.id)
    }
    
    
    // MARK: state
    nonisolated let id: ID = ID(value: .init())
    nonisolated let config: Config<ProjectEditor.ID>
    
    var queue: Deque<ProjectSourceEvent> = []
    
    var issue: (any Issuable)?
    
    
    // MARK: action
    func update() async {
        await update(mutateHook: nil)
    }
    func update(mutateHook:Hook?) async {
        // mutate
        await mutateHook?()
        guard id.isExist else { setIssue(Error.projectUpdaterIsDeleted); return }
        let projectEditorRef = config.parent.ref!
        let config = self.config
        
        while queue.isEmpty == false {
            let event = queue.removeFirst()
            switch event {
            case .modified(let newName):
                projectEditorRef.name = newName
            case .added(let systemSource, let system):
                guard let systemBoard = projectEditorRef.systemBoard,
                      let systemBoardRef = systemBoard.ref else { return }
                if systemBoardRef.isExist(system) { return }
                
                let systemSourceLink = SystemSourceLink(mode: config.mode,
                                                        object: systemSource)
                let newConfig = systemBoardRef.config.setParent(systemBoard)
                let systemModelRef = SystemModel(config: newConfig,
                                                 target: system,
                                                 sourceLink: systemSourceLink)
                systemBoardRef.models.insert(systemModelRef.id)
            case .removed(let system):
                guard let systemBoard = projectEditorRef.systemBoard,
                      let systemBoardRef = systemBoard.ref else { return }
                guard systemBoardRef.isExist(system) else { return }
                
                let systemModel = systemBoardRef.models.first { $0.ref?.target == system }
                guard let systemModel else { return }
                
                systemModel.ref?.delete()
                systemBoardRef.models.remove(systemModel)
            }
        }
    }
    
    
    
    
    // MARK: value
    @MainActor
    struct ID: Sendable, Hashable {
        let value: UUID
        var isExist: Bool {
            ProjectUpdaterManager.container[self] != nil
        }
        var ref: ProjectUpdater? {
            ProjectUpdaterManager.container[self]
        }
    }
    enum Error: String, Swift.Error {
        case projectUpdaterIsDeleted
    }
}


// MARK: Object Manager
@MainActor
fileprivate final class ProjectUpdaterManager: Sendable {
    // MARK: state
    fileprivate static var container: [ProjectUpdater.ID: ProjectUpdater] = [:]
    fileprivate static func register(_ object: ProjectUpdater) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: ProjectUpdater.ID) {
        container[id] = nil
    }
}
