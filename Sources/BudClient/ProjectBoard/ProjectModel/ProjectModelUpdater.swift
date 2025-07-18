//
//  ProjectModelUpdater.swift
//  BudClient
//
//  Created by 김민우 on 7/16/25.
//
import Foundation
import Values
import BudServer
import Collections

private let logger = WorkFlow.getLogger(for: "ProjectModelUpdater")


// MARK: Object
extension ProjectModel {
    @MainActor @Observable
    final class Updater: Sendable, UpdaterInterface, Debuggable {
        // MARK: core
        init(owner: ProjectModel.ID) {
            self.owner = owner
        }
        
        
        // MARK: state
        nonisolated let id = UUID()
        nonisolated let owner: ProjectModel.ID
        
        var queue: Deque<ProjectSourceEvent> = []
        var issue: (any Issuable)?
        
        
        // MARK: action
        func update(captureHook: Hook? = nil) async {
            logger.start()
            
            // capture
            await captureHook?()
            guard let projectModelRef = owner.ref else {
                setIssue(Error.projectModelIsDeleted)
                logger.failure("ProjectModel이 존재하지 않아 실행 취소됩니다.")
                return
            }
            let projectBoardRef = projectModelRef.config.parent.ref!
            
            // mutate
            while queue.isEmpty == false {
                let event = queue.removeFirst()
                
                switch event {
                // modify ProjectModel
                case .modified(let diff):
                    guard let modifiedModel = projectBoardRef.projects[diff.target] else {
                        setIssue(Error.alreadyRemoved)
                        logger.failure(Error.alreadyRemoved)
                        return
                    }
                    
                    modifiedModel.ref?.name = diff.name
                    
                    logger.finished("modified ProjectModel")
                    
                // remove ProjectModel
                case .removed(let diff):
                    guard let removedModelRef = projectBoardRef.projects[diff.target]?.ref else {
                        setIssue(Error.alreadyRemoved)
                        logger.failure(Error.alreadyRemoved)
                        return
                    }
                    
                    for systemModel in removedModelRef.systems.values {
                        systemModel.ref?.delete()
                    }
                    
                    removedModelRef.delete()
                    projectBoardRef.projects[diff.target] = nil
                    
                    logger.finished("removed ProjectModel")
                    
                // create SystemModel
                case .added(let sysDiff):
                    guard projectModelRef.systems[sysDiff.target] == nil else {
                        setIssue(Error.alreadyAdded)
                        logger.failure("SystemModel이 이미 존재합니다.")
                        return
                    }
                    
                    let newConfig = projectModelRef.config.setParent(owner)
                    
                    let systemModelRef = SystemModel(
                        config: newConfig,
                        target: sysDiff.target,
                        name: sysDiff.name,
                        location: sysDiff.location,
                        source: sysDiff.id)
                    
                    projectModelRef.systems[sysDiff.target] = systemModelRef.id
                    
                    logger.finished("added SystemModel")
                }
                
            }
            
            
        }
        
        
        // MARK: value
        enum Error: String, Swift.Error {
            case projectModelIsDeleted
            case alreadyAdded
            case alreadyRemoved
        }
    }
}
