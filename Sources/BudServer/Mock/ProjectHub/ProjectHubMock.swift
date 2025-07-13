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
    init() {
        ProjectHubMockManager.register(self)
    }
    
    
    // MARK: state
    package nonisolated let id: ID = ID()
    
    package var projectSources: Set<ProjectSourceMock.ID> = []
    
    private var tickets: Deque<CreateProject> = []
    package func insertTicket(_ ticket: CreateProject) async {
        tickets.append(ticket)
    }
    
    var eventHandlers: [ObjectID:Handler<ProjectHubEvent>] = [:]
    package func hasHandler(requester: ObjectID) -> Bool {
        eventHandlers[requester] != nil
    }
    package func setHandler(requester: ObjectID,
                            user: UserID,
                            handler: Handler<ProjectHubEvent>) {
        eventHandlers[requester] = handler
    }
    package func removeHandler(requester: ObjectID) async {
        eventHandlers[requester] = nil
    }
    
    package func notifyNameChanged(_ project: ProjectID) {
        let projectSource = projectSources.first {
            $0.ref?.target == project
        }
        guard let projectSourceRef = projectSource?.ref else {
            return
        }
        
        let diff = ProjectSourceDiff(id: projectSourceRef.id,
                                     target: projectSourceRef.target,
                                     name: projectSourceRef.name)
        
        for (_, handler) in eventHandlers {
            handler.execute(.modified(diff))
        }
    }
    
    
    // MARK: action
    package func createNewProject() async {
        let workflow = WorkFlow.id
        
        // mutate
        while tickets.isEmpty == false {
            let ticket = tickets.removeFirst()
            
            let projectSourceRef = ProjectSourceMock(
                projectHub: self.id,
                target: ticket.target,
                creator: ticket.creator,
                name: ticket.name)

            projectSources.insert(projectSourceRef.id)
            
            // notify
            let diff = ProjectSourceDiff(id: projectSourceRef.id,
                                         target: projectSourceRef.target,
                                         name: projectSourceRef.name)
            
            let event = ProjectHubEvent.added(diff)
            for handler in eventHandlers.values {
                handler.execute(event)
            }
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
}


// MARK: ObjectManager
@Server
fileprivate final class ProjectHubMockManager: Sendable {
    fileprivate static var container: [ProjectHubMock.ID : ProjectHubMock] = [:]
    fileprivate static func register(_ object: ProjectHubMock) {
        container[object.id] = object
    }
}
