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

private let logger = WorkFlow.getLogger(for: "ProjectBoardUpdater")


// MARK: Object
@MainActor @Observable
final class ProjectBoardUpdater: Debuggable, UpdaterInterface {
    // MARK: core
    init(config: Config<ProjectBoard.ID>) {
        self.config = config
    }
    
    
    // MARK: state
    nonisolated let config: Config<ProjectBoard.ID>
   
    var queue: Deque<ProjectHubEvent> = []
    
    var issue: (any Issuable)?
    
    
    // MARK: action
    func update() async {
        // capture
        let config = self.config
        let projectBoardRef = config.parent.ref!
        
        // mutate
        while queue.isEmpty == false {
            let event = queue.removeFirst()
            switch event {
            case .added(let diff):
                if projectBoardRef.isEditorExist(target: diff.target) {
                    setIssue(Error.alreadyAdded); return
                }
                
                // create ProjectEditor
                let projectEditorRef = ProjectEditor(config: config,
                                                     target: diff.target,
                                                     name: diff.name,
                                                     source: diff.id)
                
                projectBoardRef.editors.append(projectEditorRef.id)
                logger.success("update(\(diff.id)")
            case .modified(let diff):
                // update ProjectEditor
                guard let projectEditor = projectBoardRef.getProjectEditor(diff.target),
                      let projectEditorRef = projectEditor.ref else { return }
                
                projectEditorRef.name = diff.name
                logger.success("modified(\(diff.id)")
            case .removed(let diff):
                // remove ProjectEditor
                guard let projectEditor = projectBoardRef.getProjectEditor(diff.target),
                      let projectEditorRef = projectEditor.ref else {
                    setIssue(Error.alreadyRemoved); return
                }
                
                projectEditorRef.delete()
                projectBoardRef.editors.removeAll { $0 == projectEditor }
                logger.success("removed(\(diff.id)")
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
