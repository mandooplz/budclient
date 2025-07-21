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

private let logger = BudLogger("SystemModelUpdater")


// MARK: Object
extension SystemModel {
    @MainActor @Observable
    final class Updater: Sendable, Debuggable, UpdaterInterface, Hookable {
        // MARK: core
        init(owner: SystemModel.ID) {
            self.owner = owner
        }
        
        
        // MARK: state
        nonisolated let owner: SystemModel.ID
        
        var queue: Deque<SystemSourceEvent> = []
        var issue: (any IssueRepresentable)?
        
        package var captureHook: Hook?
        package var computeHook: Hook?
        package var mutateHook: Hook?
        
        // MARK: action
        func update() async {
            logger.start()

            // capture
            await mutateHook?()
            guard let systemModelRef = owner.ref else {
                setIssue(Error.systemModelIsDeleted)
                logger.failure("SystemModel이 존재하지 않아 update 취소됩니다.")
                return
            }
            let projectModelRef = systemModelRef.config.parent.ref!
            let callback = systemModelRef.callback
            
            let config = systemModelRef.config.setParent(owner)
            
            // mutate
            while queue.isEmpty == false {
                let event = queue.removeFirst()
                
                switch event {
                case .removed:
                    // remove SystemModel
                    for objectModel in systemModelRef.objects.values {
                        objectModel.ref?.delete()
                    }
                    
                    systemModelRef.delete()
                    projectModelRef.systems[systemModelRef.target] = nil
                    
                    logger.end("removed SystemModel")
                    
                case .modified(let diff):
                    // modified SystemModel
                    guard let modifiedModel = projectModelRef.systems[diff.target] else {
                        setIssue(Error.alreadyRemoved)
                        logger.failure(Error.alreadyRemoved)
                        return
                    }
                    
                    modifiedModel.ref?.name = diff.name
                    modifiedModel.ref?.location = diff.location
                    
                    logger.end("modified SystemModel")
                    
                case .objectAdded(let diff):
                    // create ObjectModel
                    guard systemModelRef.objects[diff.target] == nil else {
                        setIssue(Error.alreadyAdded)
                        logger.failure("\(diff.target)에 대응되는 ObjectModel이 이미 존재합니다.")
                        return
                    }
                    
                    let objectModelRef = ObjectModel(config: config,
                                                     diff: diff)
                    systemModelRef.objects[diff.target] = objectModelRef.id
                    
                    
                    switch diff.role {
                    case .root:
                        systemModelRef.root = objectModelRef.id
                        
                        logger.end("created RootObjectModel")
                    case .node:
                        let parent = diff.parent!
                        
                        let parentObjectModel = systemModelRef.objects[parent]
                        
                        parentObjectModel?.ref?.childs.append(diff.target)
                        
                        logger.end("created NodeObjectModel")
                    }
                    
                case .flowAdded:
                    // create FlowModel
                    logger.failure("미구현")
                    return
                }
            }
            
            callback?()
        }
        
        
        // MARK: value
        enum Error: String, Swift.Error {
            case systemModelIsDeleted
            case alreadyAdded, alreadyRemoved
        }
    }
}
