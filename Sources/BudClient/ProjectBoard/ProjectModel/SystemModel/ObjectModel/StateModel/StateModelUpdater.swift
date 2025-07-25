//
//  StateModelUpdater.swift
//  BudClient
//
//  Created by 김민우 on 7/17/25.
//
import Foundation
import Values
import Collections
import BudServer

private let logger = BudLogger("StateModelUpdater")


// MARK: Object
extension StateModel {
    @MainActor @Observable
    final class Updater: Debuggable, Hookable, UpdaterInterface {
        // MARK: core
        init(owner: StateModel.ID) {
            self.owner = owner
        }
        
        
        // MARK: state
        nonisolated let owner: StateModel.ID
        
        var queue: Deque<StateSourceEvent> = []
        
        var issue: (any IssueRepresentable)?
        var captureHook: Hook?
        var computeHook: Hook?
        var mutateHook: Hook?
        
        
        // MARK: action
        func update() async {
            logger.start()
            
            // capture
            await captureHook?()
            guard queue.count > 0 else {
                setIssue(Error.eventQueueIsEmpty)
                logger.failure("처리할 이벤트가 없습니다.")
                return
            }
            
            // mutate
            while queue.isEmpty == false {
                                
                guard let stateModelRef = owner.ref,
                let objectModelRef = stateModelRef.config.parent.ref else {
                    setIssue(Error.stateModelIsDeleted)
                    logger.failure("StateModel이 존재하지 않아 실행 취소됩니다.")
                    return
                }
                let event = queue.removeFirst()
                let newConfig = stateModelRef.config.setParent(stateModelRef.id)
                
                switch event {
                case .modified(let diff):
                    stateModelRef.name = diff.name
                    stateModelRef.nameInput = diff.name
                    
                    stateModelRef.accessLevel = diff.accessLevel
                    stateModelRef.accessLevelInput = diff.accessLevel
                    
                    stateModelRef.stateValue = diff.stateValue
                    stateModelRef.stateValueInput = diff.stateValue
                    
                    logger.end("modified StateModel")
                case .removed:
                    stateModelRef.getters.values
                        .compactMap { $0.ref }
                        .forEach { $0.delete() }
                    
                    stateModelRef.setters.values
                        .compactMap { $0.ref }
                        .forEach { $0.delete() }
                    
                    objectModelRef.states[stateModelRef.target] = nil
                    stateModelRef.delete()
                    
                    logger.end("removed StateModel")
                case .getterAdded(let diff):
                    guard stateModelRef.getters[diff.target] == nil else {
                        logger.failure("GetterID를 target으로 갖는 GetterModel이 이미 존재합니다.")
                        return
                    }
                    
                    let getterModelRef = GetterModel(
                        config: newConfig,
                        diff: diff)
                    stateModelRef.getters[diff.target] = getterModelRef.id
                    
                    logger.end("added GetterModel")
                case .getterDuplicated(let getter, let diff):
                    guard stateModelRef.getters[diff.target] == nil else {
                        logger.failure("복제된 GetterModel이 이미 존재합니다.")
                        return
                    }
                    
                    guard let index = stateModelRef.getters.index(forKey: getter) else {
                        logger.failure("복사하려는 GetterModel이 존재하지 않아 취소됩니다.")
                        return
                    }
                    
                    let newIndex = index.advanced(by: 1)
                    
                    let newGetterModelRef = GetterModel(
                        config: newConfig,
                        diff: diff)
                    
                    stateModelRef.getters.updateValue(newGetterModelRef.id, forKey: newGetterModelRef.target, insertingAt: newIndex)
                    
                    logger.end("duplicate Getter")
                case .setterAdded(let diff):
                    guard stateModelRef.setters[diff.target] == nil else {
                        logger.failure("SetterID를 target으로 갖는 SetterModel이 이미 존재합니다.")
                        return
                    }
                    
                    let setterModelRef = SetterModel(config: newConfig, diff: diff)
                    stateModelRef.setters[diff.target] = setterModelRef.id
                    
                    logger.end("added SetterModel")
                    
                case .setterDuplicated(let setter, let diff):
                    guard stateModelRef.setters[diff.target] == nil else {
                        logger.failure("SetterID를 target으로 갖는 SetterModel이 이미 존재합니다.")
                        return
                    }
                    
                    guard let index = stateModelRef.setters.index(forKey: setter) else {
                        logger.failure("복사하려는 SetterModel이 존재하지 않아 취소됩니다.")
                        return
                    }
                    
                    let newIndex = index.advanced(by: 1)
                    
                    let newSetterModeRef = SetterModel(config: newConfig, diff: diff)
                    
                    stateModelRef.setters.updateValue(newSetterModeRef.id, forKey: newSetterModeRef.target, insertingAt: newIndex)
                    
                    logger.end("duplicate Setter")
                }
            }
        }
        
        
        // MARK: Helphers
        
        
        // MARK: value
        public enum Error: String, Swift.Error {
            case eventQueueIsEmpty
            case stateModelIsDeleted
        }
    }
}
