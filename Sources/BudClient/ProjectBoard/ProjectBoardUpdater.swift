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

private let logger = BudLogger("ProjectBoard.Updater")


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
        var issue: (any IssueRepresentable)?
        
        
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
                    let newProject = diff.target
                    
                    guard projectBoardRef.projects[newProject] == nil else {
                        setIssue(Error.alreadyAdded)
                        logger.failure("Project에 연결된 ProjectModel이 이미 존재합니다.")
                        return
                    }

                    // create ProjectModel
                    let projectModelRef = ProjectModel(config: config, diff: diff)
                    
                    projectBoardRef.projects[newProject] = projectModelRef.id

                    logger.end("added \(diff.id)")
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

