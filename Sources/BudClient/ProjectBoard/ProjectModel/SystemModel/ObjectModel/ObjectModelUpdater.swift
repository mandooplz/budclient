//
//  ObjectModelUpdater.swift
//  BudClient
//
//  Created by 김민우 on 7/17/25.
//
import Foundation
import Values
import BudServer
import Collections

private let logger = BudLogger("ObjectModelUpdater")


// MARK: Object
extension ObjectModel {
    @MainActor @Observable
    final class Updater: UpdaterInterface {
        // MARK: core
        init(owner: ObjectModel.ID) {
            self.owner = owner
        }
        
        
        // MARK: state
        nonisolated let id = UUID()
        nonisolated let owner: ObjectModel.ID
        
        var queue: Deque<ObjectSourceEvent> = []
        var issue: (any IssueRepresentable)?
        
        package var captureHook: Hook?
        package var computeHook: Hook?
        package var mutateHook: Hook?
        
        
        // MARK: action
        func update() async {
            logger.start()
            
            // capture
            await captureHook?()
            guard queue.count > 0  else {
                setIssue(Error.eventQueueIsEmpty)
                logger.failure("이벤트 큐가 비어있습니다.")
                return
            }
            
            
            // mutate
            await mutateHook?()
            while queue.isEmpty == false {
                guard let objectModelRef = owner.ref else {
                    setIssue(Error.objectModelIsDeleted)
                    logger.failure("ObjectModel이 존재하지 않아 실행 취소됩니다.")
                    return
                }
                
                let systemModelRef = objectModelRef.config.parent.ref!
                let newConfig = objectModelRef.config.setParent(objectModelRef.id)
                let event = queue.removeFirst()
                
                switch event {
                case .modified(let diff):
                    // modify ObjectModel
                    objectModelRef.name = diff.name
                    
                    logger.end("modified ObjectModel")
                    return
                case .removed:
                    // remove ObjectModel
                    objectModelRef.states.values
                        .compactMap { $0.ref }
                        .forEach { cleanUpStateModel($0) }
                    
                    objectModelRef.actions.values
                        .compactMap { $0.ref }
                        .forEach { $0.delete() }
                    
                    // delte ObjectModel Recursively
                    if objectModelRef.role == .root {
                        systemModelRef.root = nil
                    }
                    cleanUpChildObjectModel(systemModelRef, objectModelRef)
                    
                    logger.end("removed \(objectModelRef.id)")
                case .stateAdded(let diff):
                    // create StateModel
                    guard objectModelRef.states[diff.target] == nil else {
                        logger.failure("System에 대응되는 SystemModel이 이미 존재합니다.")
                        return
                    }
                    
                    let stateModelRef = StateModel(
                        config: newConfig,
                        diff: diff)
                    objectModelRef.states[diff.target] = stateModelRef.id
                    
                    logger.end("added StateModel")
                    
                case .actionAdded(let diff):
                    // create ActionModel
                    guard objectModelRef.actions[diff.target] == nil else {
                        logger.failure("Action에 대응되는 ActionModel이 이미 존재합니다.")
                        return
                    }
                    
                    let actionModelRef = ActionModel(config: newConfig, diff: diff)
                    objectModelRef.actions[diff.target] = actionModelRef.id
                    
                    logger.end("added ActionModel")
                }
            }
        }
        
        
        // MARK: Helphers
        private func cleanUpStateModel(_ stateModelRef: StateModel) {
            stateModelRef.getters.values
                .compactMap { $0.ref }
                .forEach { $0.delete() }
            
            stateModelRef.setters.values
                .compactMap { $0.ref }
                .forEach { $0.delete() }
            
            stateModelRef.delete()
        }
        private func cleanUpChildObjectModel(_ systemModelRef: SystemModel,
                                             _ objectModelRef: ObjectModel) {
            
            for childObject in objectModelRef.childs {
                let childObjectModel = systemModelRef.objects[childObject]!
                cleanUpChildObjectModel(systemModelRef, childObjectModel.ref!)
            }
            
            systemModelRef.objects[objectModelRef.target] = nil
            objectModelRef.delete()
        }
        
        
        // MARK: value
        enum Error: String, Swift.Error {
            case objectModelIsDeleted
            case eventQueueIsEmpty
        }
        typealias Event = ObjectSourceEvent
    }
}

