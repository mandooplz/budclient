//
//  ProjectBoardUpdater.swift
//  BudClient
//
//  Created by 김민우 on 6/30/25.
//
import Foundation
import Values
import BudServer
import Collections

private let logger = WorkFlow.getLogger(for: "ProjectBoard.Updater")


// MARK: Object
extension ProjectBoard {
    @MainActor @Observable
    final class Updater: Debuggable, UpdaterInterface {
        // MARK: core
        init(owner: ProjectBoard.ID) {
            self.owner = owner
        }
        
        
        // MARK: state
        nonisolated let id = UUID()
        nonisolated let owner: ProjectBoard.ID
       
        var queue: Deque<ProjectHubEvent> = []
        var issue: (any Issuable)?
        
        
        // MARK: action
        func update() async {
            logger.start()
            
            // capture
            guard let projectBoardRef = owner.ref else {
                return
            }
            let config = projectBoardRef.config.setParent(owner)
            
            // mutate
            while queue.isEmpty == false {
                let event = queue.removeFirst()
                switch event {
                case .added(let diff):
                    if projectBoardRef.isEditorExist(target: diff.target) {
                        setIssue(Error.alreadyAdded)
                        logger.failure(Error.alreadyAdded)
                        return
                    }
                    
                    // create ProjectEditor
                    let projectModelRef = ProjectEditor(config: config,
                                                         target: diff.target,
                                                         name: diff.name,
                                                         source: diff.id)
                    
                    projectBoardRef.projects.append(projectModelRef.id)
                    
                    logger.finished("added \(diff.id)")
                case .modified(let diff):
                    // update ProjectEditor
                    guard let projectEditor = projectBoardRef.getProjectEditor(diff.target),
                          let projectEditorRef = projectEditor.ref else { return }
                    
                    projectEditorRef.name = diff.name
                    
                    logger.finished("modified \(diff.id)")
                case .removed(let diff):
                    // remove ProjectEditor
                    guard let projectEditor = projectBoardRef.getProjectEditor(diff.target),
                          let projectEditorRef = projectEditor.ref else {
                        setIssue(Error.alreadyRemoved)
                        logger.failure(Error.alreadyRemoved)
                        return
                    }
                    
                    projectEditorRef.delete()
                    projectBoardRef.editors.removeAll { $0 == projectEditor }
                    
                    logger.finished("removed \(diff.id)")
                }
            }
        }
        
        
        // MARK: value
        enum Error: String, Swift.Error {
            case updaterIsDeleted
            case alreadyAdded, alreadyRemoved
            case projectSourceDoesNotExist
        }
    }
}

