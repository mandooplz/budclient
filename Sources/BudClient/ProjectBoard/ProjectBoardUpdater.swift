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
    final class Updater: Debuggable, UpdaterInterface, Hookable {
        // MARK: core
        init(owner: ProjectBoard.ID) {
            self.owner = owner
        }
        
        
        // MARK: state
        nonisolated let id = UUID()
        nonisolated let owner: ProjectBoard.ID
       
        var queue: Deque<ProjectHubEvent> = []
        var issue: (any IssueRepresentable)?
        
        package var captureHook: Hook?
        package var computeHook: Hook?
        package var mutateHook: Hook?
        
        
        // MARK: action
        func update() async {
            logger.start()
            
            // capture
            await captureHook?()
            guard let projectBoardRef = owner.ref else {
                setIssue(Error.projectBoardIsDeleted)
                logger.failure("ProjectBoard가 존재하지 않아 update가 취소됩니다.")
                return
            }
            let config = projectBoardRef.config.setParent(owner)
            
            // mutate
            while queue.isEmpty == false {
                let event = queue.removeFirst()
                switch event {
                case .projectAdded(let diff):
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
            case projectBoardIsDeleted
            case alreadyAdded
        }
    }
}

