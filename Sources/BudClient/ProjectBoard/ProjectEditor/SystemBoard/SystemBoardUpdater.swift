//
//  SystemBoardUpdater.swift
//  BudClient
//
//  Created by 김민우 on 7/8/25.
//
import Foundation
import Values
import Collections
import BudServer


// MARK: Object
@MainActor @Observable
final class SystemBoardUpdater: Sendable, Debuggable {
    // MARK: core
    init(config: Config<SystemBoard.ID>) {
        self.config = config
        
        SystemBoardUpdaterManager.container[self.id] = self
    }
    func delete() {
        SystemBoardUpdaterManager.container[self.id] = nil
    }
    
    
    // MARK: state
    nonisolated let id = ID()
    nonisolated let config: Config<SystemBoard.ID>
    
    
    var queue: Deque<ProjectSourceEvent> = []
    
    var issue: (any Issuable)?
    
    
    // MARK: action
    func update(mutateHook: Hook? = nil) async {
        // mutate
        await mutateHook?()
        guard id.isExist else { setIssue(Error.updaterIsDeleted); return }
        let config = self.config
        let systemBoardRef = config.parent.ref!
        let projectEditorRef = config.parent.ref!.config.parent.ref!
        
        while queue.isEmpty == false {
            let event = queue.removeFirst()
            switch event {
            case .added(let systemSource, let system):
                if systemBoardRef.isExist(system) { return }
                
                let systemSourceLink = SystemSourceLink(mode: config.mode,
                                                        object: systemSource)
                let systemModelRef = SystemModel(config: config,
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
            default:
                // logger 기록?
                return
            }
        }
    }
    
    
    // MARK: value
    @MainActor
    struct ID: Sendable, Hashable {
        let value: UUID
        nonisolated init(value: UUID = UUID()) {
            self.value = value
        }
        
        var isExist: Bool {
            SystemBoardUpdaterManager.container[self] != nil
        }
        var ref: SystemBoardUpdater? {
            SystemBoardUpdaterManager.container[self]
        }
    }
    enum Error: String, Swift.Error {
        case updaterIsDeleted
    }
}


// MARK: Object Manager
@MainActor @Observable
fileprivate final class SystemBoardUpdaterManager: Sendable {
    // MARK: state
    fileprivate static var container: [SystemBoardUpdater.ID: SystemBoardUpdater] = [:]
}
