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
            guard let stateModelRef = owner.ref else {
                setIssue(Error.stateModelIsDeleted)
                logger.failure("StateModel이 존재하지 않아 실행 취소됩니다.")
                return
            }
            let newConfig = stateModelRef.config.setParent(stateModelRef.id)
            
            // mutate
            while queue.isEmpty == false {
                let event = queue.removeFirst()
                
                switch event {
                case .modified(let stateSourceDiff):
                    fatalError()
                case .removed:
                    fatalError()
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
                case .setterAdded(let diff):
                    guard stateModelRef.setters[diff.target] == nil else {
                        logger.failure("SetterID를 target으로 갖는 SetterModel이 이미 존재합니다.")
                        return
                    }
                    
                    let setterModelRef = SetterModel(config: newConfig, diff: diff)
                    stateModelRef.setters[diff.target] = setterModelRef.id
                    
                    logger.end("added SetterModel")
                }
            }
        }
        
        
        // MARK: value
        public enum Error: String, Swift.Error {
            case stateModelIsDeleted
        }
    }
}
