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
        
        
        // MARK: action
        func update(mutateHook: Hook? = nil) async {
            logger.start()
            
            guard let objectModelRef = owner.ref else {
                setIssue(Error.objectModelIsDeleted)
                logger.failure("ObjectModel이 존재하지 않아 실행 취소됩니다.")
                return
            }
            
            let systemModelRef = objectModelRef.config.parent.ref!
            
            while queue.isEmpty == false {
                let event = queue.removeFirst()
                
                
                
                switch event {
                case .modified(let diff):
                    objectModelRef.name = diff.name
                    
                    logger.finished("modified ObjectModel")
                    return
                case .removed:
                    systemModelRef.objects[objectModelRef.target] = nil
                    objectModelRef.delete()
                    
                    logger.finished("removed \(objectModelRef.id)")
                case .addedState:
                    
                    logger.failure("아직 미구현")
                    return
                }
            }
        }
        
        
        // MARK: value
        enum Error: String, Swift.Error {
            case objectModelIsDeleted
        }
        typealias Event = ObjectSourceEvent
    }
}

