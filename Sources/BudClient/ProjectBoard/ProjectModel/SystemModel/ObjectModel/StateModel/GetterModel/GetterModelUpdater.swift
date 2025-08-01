//
//  GetterModelUpdater.swift
//  BudClient
//
//  Created by 김민우 on 7/22/25.
//
import Foundation
import Values
import Collections
import BudServer

private let logger = BudLogger("GetterModelUpdater")


// MARK: Object
extension GetterModel {
    @MainActor @Observable
    final class Updater: Debuggable, Hookable, UpdaterInterface {
        // MARK: core
        init(owner: GetterModel.ID) {
            self.owner = owner
        }
        
        
        // MARK: state
        nonisolated let owner: GetterModel.ID
        
        var queue: Deque<GetterSourceEvent> = []
        
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
                logger.failure("처리할 Event가 존재하지 않습니다.")
                return
            }
            
            // mutate
            await mutateHook?()
            while queue.isEmpty == false {
                guard let getterModelRef = owner.ref,
                    let stateModelRef = getterModelRef.config.parent.ref else {
                    setIssue(Error.getterModelIsDeleted)
                    logger.failure("GetterModel이 존재하지 않아 실행 취소됩니다.")
                    return
                }
                let event = queue.removeFirst()
                
                switch event {
                case .modified(let diff):
                    getterModelRef.name = diff.name
                    getterModelRef.nameInput = diff.name
                    
                    getterModelRef.parameters = diff.parameters
                    getterModelRef.parameterInput = diff.parameters
                    
                    getterModelRef.result = diff.result
                    getterModelRef.resultInput = diff.result
                    
                    logger.end("modified GetterModel")
                case .removed:
                    // remove GetterModel
                    stateModelRef.getters[getterModelRef.target] = nil
                    getterModelRef.delete()
                    
                    logger.end("removed GetterModel")
                }
            }
        }
        
        
        // MARK: value
        public enum Error: String, Swift.Error {
            case eventQueueIsEmpty
            case getterModelIsDeleted
        }
    }
}
