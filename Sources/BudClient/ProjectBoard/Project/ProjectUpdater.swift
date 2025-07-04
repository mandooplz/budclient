//
//  ProjectUpdater.swift
//  BudClient
//
//  Created by 김민우 on 7/3/25.
//
import Foundation
import Tools
import Collections


// MARK: Object
@MainActor
final class ProjectUpdater: Debuggable {
    // MARK: core
    init(config: Config<Project.ID>) {
        self.config = config
        
        ProjectUpdaterManager.register(self)
    }
    func delete() {
        ProjectUpdaterManager.unregister(self.id)
    }
    
    
    // MARK: state
    nonisolated let id: ID = ID(value: .init())
    nonisolated let config: Config<Project.ID>
    
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
        let projectRef = config.parent.ref!
        
        while queue.isEmpty == false {
            let event = queue.removeFirst()
            switch event {
            case .modified(let newName):
                projectRef.name = newName
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
