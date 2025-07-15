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

private let logger = WorkFlow.getLogger(for: "SystemModelUpdater")


// MARK: Object
@MainActor @Observable
final class SystemModelUpdater: Sendable, Debuggable, UpdaterInterface {
    // MARK: core
    init(config: Config<SystemModel.ID>) {
        self.config = config
    }
    
    
    // MARK: state
    nonisolated let config: Config<SystemModel.ID>
    
    var issue: (any Issuable)?
    var queue: Deque<SystemSourceEvent> = []
    
    
    // MARK: action
    func update() async {
        await self.update(mutateHook: nil)
    }
    func update(mutateHook: Hook?) async {
        // capture
        await mutateHook?()
        guard let systemModelRef = self.config.parent.ref else {
            setIssue(Error.systemModelIsDeleted)
            logger.failure("SystemModel이 존재하지 않아 update 취소됩니다.")
            return
        }
        let config = self.config
        
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
                                                 target: diff.target,
                                                 config: config)
                
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
