//
//  SystemModelUpdater.swift
//  BudClient
//
//  Created by 김민우 on 7/9/25.
//
import Foundation
import Values
import Collections
import BudServer

private let logger = WorkFlow.getLogger(for: "SystemModel.Updater")


// MARK: Object
extension SystemModel {
    @MainActor @Observable
    final class Updater: Sendable, Debuggable, UpdaterInterface {
        // MARK: core
        init(owner: SystemModel.ID) {
            self.owner = owner
        }
        
        
        // MARK: state
        nonisolated let owner: SystemModel.ID
        
        var queue: Deque<SystemSourceEvent> = []
        var issue: (any Issuable)?
        
        
        // MARK: action
        func update(mutateHook: Hook? = nil) async {
            // capture
            await mutateHook?()
            guard let systemModelRef = owner.ref,
                let projectModelRef = systemModelRef.config.parent.ref else {
                setIssue(Error.systemModelIsDeleted)
                logger.failure("SystemModel이 존재하지 않아 update 취소됩니다.")
                return
            }
            let config = systemModelRef.config.setParent(owner)
            
            // mutate
            while queue.isEmpty == false {
                let event = queue.removeFirst()
                
                switch event {
                case .removed(let diff):
                    // remove SystemModel -> SystemModel.Updater
                    guard projectModelRef.systems[diff.target] != nil else {
                        setIssue(Error.alreadyRemoved)
                        logger.failure(Error.alreadyRemoved)
                        return
                    }
                    
                    projectModelRef.systems[diff.target] = nil
                    systemModelRef.delete()
                case .modified(let diff):
                    // modified SystemModel -> SystemModel.updater
                    systemModelRef.name = diff.name
                    systemModelRef.location = diff.location
                
                case .objectAdded(let diff):
                    // create ObjectModel
                    guard systemModelRef.objects[diff.target] == nil else {
                        setIssue(Error.alreadyAdded)
                        logger.failure("\(diff.target)에 대응되는 ObjectModel이 이미 존재합니다.")
                        return
                    }
                    
                    let objectModelRef = ObjectModel(name: diff.name,
                                                     role: diff.role,
                                                     target: diff.target,
                                                     config: config)
                    
                    if diff.role == .root {
                        systemModelRef.root = objectModelRef.id
                    }
                    
                    systemModelRef.objects[diff.target] = objectModelRef.id
                    
                case .flowAdded(let diff):
                    return
                }
            }
        }
        
        
        // MARK: value
        enum Error: String, Swift.Error {
            case systemModelIsDeleted
            case alreadyAdded, alreadyRemoved
        }
    }
}
