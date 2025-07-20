//
//  ProjectHubMock.swift
//  BudClient
//
//  Created by 김민우 on 6/30/25.
//
import Foundation
import Values
import Collections

private let logger = BudLogger("ProjectHubMock")


// MARK: Object
@Server
package final class ProjectHubMock: ProjectHubInterface {
    // MARK: core
    init(user: UserID) {
        self.user = user
        
        ProjectHubMockManager.register(self)
    }
    
    
    // MARK: state
    package nonisolated let id: ID = ID()
    package nonisolated let user: UserID
    
    package var projectSources: Set<ProjectSourceMock.ID> = []
    
    var handlers: [ObjectID:EventHandler] = [:]
    package func appendHandler(for requester: ObjectID, _ handler: EventHandler) {
        self.handlers[requester] = handler
    }
    package func removeHandler(of requester: ObjectID) async {
        self.handlers[requester] = nil
    }
    package func synchronize(requester: ObjectID) async {
        let diffs = self.projectSources
            .compactMap { $0.ref }
            .map { ProjectSourceDiff($0) }
        
        for initialDiff in diffs {
            self.handlers[requester]?.execute(.added(initialDiff))
        }
    }
    
    
    // MARK: action
    package func createProject() async {
        logger.start()
        // capture
        guard id.isExist else {
            logger.failure("ProjectHubMock이 존재하지 않아 실행 취소됩니다.")
            return
        }
        
        // mutate
        let newProjectName = "Project \(Int.random(in: 1..<1000))"
        let projectSourceRef = ProjectSourceMock(
            name: newProjectName,
            creator: user,
            projectHubMockRef: self.id
        )

        projectSources.insert(projectSourceRef.id)
        
        // notify
        let diff = ProjectSourceDiff(id: projectSourceRef.id,
                                     target: projectSourceRef.target,
                                     name: projectSourceRef.name)
        
        handlers.values.forEach { eventHandler in
            eventHandler.execute(.added(diff))
        }
    }
    
    
    // MARK: value
    @Server
    package struct ID: ProjectHubIdentity {
        let value = UUID()
        nonisolated init() { }
        
        package var isExist: Bool {
            ProjectHubMockManager.container[self] != nil
        }
        package var ref: ProjectHubMock? {
            ProjectHubMockManager.container[self]
        }
    }
    package typealias EventHandler = Handler<ProjectHubEvent>
}


// MARK: ObjectManager
@Server
fileprivate final class ProjectHubMockManager: Sendable {
    fileprivate static var container: [ProjectHubMock.ID : ProjectHubMock] = [:]
    fileprivate static func register(_ object: ProjectHubMock) {
        container[object.id] = object
    }
}
