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
import os


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
            case .added(let projectSource, let project):
                if projectBoardRef.isEditorExist(target: project) {
                    setIssue(Error.alreadyAdded); return
                }
                
                // create ProjectEditor
                let sourceLink = ProjectSourceLink(mode: config.mode,
                                                   object: projectSource)
                let projectEditorRef = ProjectEditor(config: config,
                                                     target: project,
                                                     sourceLink: sourceLink)
                
                projectBoardRef.editors.append(projectEditorRef.id)
                
            case .modified(let projectSourceDiff):
                // update ProjectEditor
                let project = projectSourceDiff.target
                let newName = projectSourceDiff.name
                
                guard let projectEditor = projectBoardRef.getProjectEditor(project),
                      let projectEditorRef = projectEditor.ref else { return }
                
                projectEditorRef.name = newName
            case .removed(let project):
                // remove ProjectEditor
                guard let projectEditor = projectBoardRef.getProjectEditor(project),
                      let projectEditorRef = projectEditor.ref else {
                    setIssue(Error.alreadyRemoved); return
                }
                
                projectEditorRef.delete()
                projectBoardRef.editors.removeAll { $0 == projectEditor }
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
