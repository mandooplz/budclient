//
//  ProjectHubMock.swift
//  BudClient
//
//  Created by 김민우 on 6/30/25.
//
import Foundation
import Tools
import Collections


// MARK: Object
@Server
package final class ProjectHubMock: Sendable, Subscribable {
    // MARK: core
    package init() {
        ProjectHubMockManager.register(self)
    }
    package func delete() {
        ProjectHubMockManager.unregister(self.id)
    }
    
    
    // MARK: state
    package nonisolated let id: ID = ID()
    
    package var projectSources: Set<ProjectSourceID> = []
    
    package var tickets: Deque<ProjectTicket> = []
    package var eventHandlers: [SystemID: Handler<ProjectHubEvent>] = [:]
    
    
    // MARK: action
    package func createProjectSource() async {
        // mutate
        while tickets.isEmpty == false {
            let ticket = tickets.removeFirst()
            let projectSourceRef = ProjectSourceMock(
                projectHubRef: self,
                user: ticket.user,
                name: ticket.name)

            projectSources.insert(projectSourceRef.id)
            
            let eventHandler = eventHandlers[ticket.system]
            let event = ProjectHubEvent.added(projectSourceRef.id)
            
            // 직접 이벤트핸들러 호출
            eventHandler?.execute(event)
        }
    }
    
    
    // MARK: value
    package struct ID: Sendable, Hashable {
        package let value: UUID
        package nonisolated init(value: UUID = UUID()) {
            self.value = value
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
    fileprivate static func unregister(_ id: ProjectHubMock.ID) {
        container[id] = nil
    }
}
