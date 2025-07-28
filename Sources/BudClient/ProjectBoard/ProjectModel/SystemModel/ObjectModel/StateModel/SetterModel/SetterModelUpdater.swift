//
//  SetterModelUpdater.swift
//  BudClient
//
//  Created by 김민우 on 7/22/25.
//
import Foundation
import Values
import Collections
import BudServer

private let logger = BudLogger("SetterModelUpdater")


// MARK: Object
extension SetterModel {
    @MainActor @Observable
    final class Updater: Debuggable, Hookable, UpdaterInterface {
        // MARK: core
        init(owner: SetterModel.ID) {
            self.owner = owner
        }
        
        
        // MARK: state
        nonisolated let owner: SetterModel.ID
        
        var queue: Deque<SetterSourceEvent> = []
        
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
                logger.failure("처리할 이벤트가 존재하지 않습니다.")
                return
            }
            
            
            // mutate
            await mutateHook?()
            while queue.isEmpty == false {
                guard let setterModelRef = owner.ref else {
                    setIssue(Error.setterModelIsDeleted)
                    logger.failure("SetterModel이 존재하지 않아 실행 취소됩니다.")
                    return
                }
                let stateModelRef = setterModelRef.config.parent.ref!
                
                let event = queue.removeFirst()
                
                switch event {
                case .modified(let diff):
                    setterModelRef.name = diff.name
                    setterModelRef.nameInput = diff.name
                    
                    setterModelRef.parameters = diff.parameters.toDictionary()
                    setterModelRef.parameterInput = diff.parameters
                    
                    logger.end("modified SetterModel")
                case .removed:
                    stateModelRef.setters[setterModelRef.target] = nil
                    setterModelRef.delete()
                    
                    logger.end("removed SetterModel")
                }                
            }
        }
        
        
        // MARK: value
        public enum Error: String, Swift.Error {
            case eventQueueIsEmpty
            case setterModelIsDeleted
        }
    }
}
