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

private let logger = BudLogger("ProjectModelUpdater")


// MARK: Object
extension ProjectModel {
    @MainActor @Observable
    final class Updater: UpdaterInterface, Hookable {
        // MARK: core
        init(owner: ProjectModel.ID) {
            self.owner = owner
        }
        
        
        // MARK: state
        nonisolated let id = UUID()
        nonisolated let owner: ProjectModel.ID
        
        var queue: Deque<ProjectSourceEvent> = []
        var issue: (any IssueRepresentable)?
        
        package var captureHook: Hook?
        package var computeHook: Hook?
        package var mutateHook: Hook?
        
        
        // MARK: action
        func update() async {
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
                    
                    logger.end("modified ProjectModel")
                    
                // remove ProjectModel
                case .removed:
                    projectModelRef.systems.values
                        .compactMap { $0.ref }
                        .flatMap { $0.objects.values }
                        .compactMap { $0.ref }
                        .forEach { cleanUpObjectModel($0) }
                    
                    projectModelRef.systems.values
                        .compactMap { $0.ref }
                        .forEach { $0.delete() }
                    
                    projectModelRef.delete()
                    projectBoardRef.projects[projectModelRef.target] = nil
                    
                    logger.end("removed ProjectModel")
                    
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
                        diff: sysDiff)
                    
                    projectModelRef.systems[sysDiff.target] = systemModelRef.id
                    
                    logger.end("added SystemModel")
                }
                
            }
        }
        
        
        // MARK: Helphers
        private func cleanUpObjectModel(_ objectModelRef: ObjectModel) {
            // delete GetterModel
            objectModelRef.states.values
                .compactMap { $0.ref }
                .flatMap { $0.getters.values }
                .compactMap { $0.ref }
                .forEach { $0.delete() }
            
            
            // delete SetterModel
            objectModelRef.states.values
                .compactMap { $0.ref }
                .flatMap { $0.setters.values }
                .compactMap { $0.ref }
                .forEach { $0.delete() }
            
            
            // delete StateModel
            objectModelRef.states.values
                .compactMap { $0.ref }
                .forEach { $0.delete() }
            
            
            // delete ActioModel
            objectModelRef.actions.values
                .compactMap { $0.ref }
                .forEach { $0.delete() }
            
            
            // delete ObjectModel
            objectModelRef.delete()
        }
        
        
        // MARK: value
        enum Error: String, Swift.Error {
            case projectModelIsDeleted
            case alreadyAdded
            case alreadyRemoved
        }
    }
}
