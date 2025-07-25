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
            guard let objectModelRef = owner.ref else {
                setIssue(Error.objectModelIsDeleted)
                logger.failure("ObjectModel이 존재하지 않아 실행 취소됩니다.")
                return
            }
            
            let systemModelRef = objectModelRef.config.parent.ref!
            let newConfig = objectModelRef.config.setParent(objectModelRef.id)
            
            // mutate
            while queue.isEmpty == false {
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
                    
                    if objectModelRef.role == .root {
                        systemModelRef.root = nil
                    }
                    
                    systemModelRef.objects[objectModelRef.target] = nil
                    objectModelRef.delete()
                    
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
                    
                case .stateDuplicated(let state, let diff):
                    // duplicate StateModel
                    guard objectModelRef.states[diff.target] == nil else {
                        logger.failure("System에 대응되는 SystemModel이 이미 존재합니다.")
                        return
                    }
                    guard let index = objectModelRef.states.index(forKey: state) else {
                        logger.failure("복사하려는 StateModel이 존재하지 않습니다.")
                        return
                    }
                    
                    let stateModelRef = StateModel(
                        config: newConfig,
                        diff: diff)
                    objectModelRef.states.updateValue(
                        stateModelRef.id,
                        forKey: stateModelRef.target,
                        insertingAt: index + 1)
                    objectModelRef.states[diff.target] = stateModelRef.id
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
        
        
        // MARK: value
        enum Error: String, Swift.Error {
            case objectModelIsDeleted
        }
        typealias Event = ObjectSourceEvent
    }
}

