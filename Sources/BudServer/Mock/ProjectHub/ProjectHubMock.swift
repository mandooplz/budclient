//
//  ProjectHubMock.swift
//  BudClient
//
//  Created by 김민우 on 6/30/25.
//
import Foundation
import Values
import Collections


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
    
    var handler: EventHandler?
    package func setHandler(_ handler: EventHandler) {
        self.handler = handler
    }
    
    
    // MARK: action
    package func createProject() async {
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
        
        handler?.execute(.added(diff))
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
