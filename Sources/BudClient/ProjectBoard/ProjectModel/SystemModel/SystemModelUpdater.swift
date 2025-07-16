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
            guard let systemModelRef = owner.ref else {
                setIssue(Error.systemModelIsDeleted)
                logger.failure("SystemModel이 존재하지 않아 update 취소됩니다.")
                return
            }
            let config = systemModelRef.config.setParent(owner)
            
            // mutate
            while queue.isEmpty == false {
                let event = queue.removeFirst()
                
                switch event {
                case .added(let diff):
                    // create ObjectModel
                    guard systemModelRef.isObjectExist(diff.target) == false else {
                        setIssue(Error.alreadyAdded)
                        logger.failure("\(diff.target)에 대응되는 ObjectModel이 이미 존재합니다.")
                        return
                    }
                    
                    let objectModelRef = ObjectModel(name: diff.name,
                                                     role: diff.role,
                                                     target: diff.target,
                                                     config: config)
                    
                    if diff.role == .root {
                        systemModelRef.rootModel = objectModelRef.id
                    }
                    
                    systemModelRef.objectModels.append(objectModelRef.id)
                    
                case .modified(let diff):
                    // modify ObjectModel
                    guard let objectModel = systemModelRef.getObjectModel(diff.target) else {
                        setIssue(Error.alreadyRemoved)
                        logger.failure("\(diff.target)에 대응되는 ObjectModel이 이미 삭제된 상태입니다.")
                        return
                    }
                    
                    objectModel.ref?.name = diff.name
                    
                case .removed(let diff):
                    // remove ObjectModel
                    guard systemModelRef.isObjectExist(diff.target) == true else {
                        setIssue(Error.alreadyRemoved)
                        logger.failure("\(diff.target)에 대응되는 ObjectModel이 이미 삭제된 상태입니다.")
                        return
                    }
                    
                    for (idx, objectModel) in systemModelRef.objectModels.enumerated() {
                        if let objectModelRef = objectModel.ref,
                           objectModelRef.target == diff.target {
                            systemModelRef.objectModels.remove(at: idx)
                            objectModelRef.delete()
                            break
                        }
                    }
                    
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
