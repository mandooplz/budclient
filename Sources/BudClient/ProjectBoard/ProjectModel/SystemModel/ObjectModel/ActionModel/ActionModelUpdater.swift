//
//  ActionModelUpdater.swift
//  BudClient
//
//  Created by 김민우 on 7/17/25.
//
import Foundation
import Values
import Collections
import BudServer

private let logger = BudLogger("ActionModel")


// MARK: Object
extension ActionModel {
    @MainActor @Observable
    final class Updater: UpdaterInterface {
        // MARK: core
        init(owner: ActionModel.ID) {
            self.owner = owner
        }
        
        
        // MARK: state
        nonisolated let id = UUID()
        nonisolated let owner: ActionModel.ID
        
        var queue: Deque<ActionSourceEvent> = []
        
        var issue: (any IssueRepresentable)?
        
        package var captureHook: Hook?
        package var computeHook: Hook?
        package var mutateHook: Hook?
        
        
        // MARK: action
        func update() async {
            logger.start()
            
            // capture
            await captureHook?()
            guard queue.count > 0 else {
                setIssue(Error.eventQueueIsEmpty)
                logger.failure("처리할 이벤트가 없어 종료됩니다.")
                return
            }
            
            // mutate
            await mutateHook?()
            while queue.isEmpty == false {
                guard let actionModelRef = owner.ref,
                      let objectModelRef = actionModelRef.config.parent.ref else {
                    setIssue(Error.actionModelIsDeleted)
                    logger.failure("ActionModel이 존재하지 않아 실행 취소됩니다.")
                    return
                }
                
                let event = queue.removeFirst()
                
                switch event {
                case .modified(let diff):
                    // modify ActionModel
                    actionModelRef.name = diff.name
                    actionModelRef.nameInput = diff.name
                    
                    logger.end("modified ActionModel")
                case .removed:
                    // remove ActionModel
                    objectModelRef.actions[actionModelRef.target] = nil
                    actionModelRef.delete()
                    
                    logger.end("removed ActionModel")
                }
            }
        }
        
        
        // MARK: value
        enum Error: String, Swift.Error {
            case actionModelIsDeleted
            case eventQueueIsEmpty
        }
    }
}
