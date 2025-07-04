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
final class ProjectHubMock: ServerObject, Subscribable {
    // MARK: core
    init() { }
    
    
    // MARK: state
    nonisolated let id: ID = ID()
    
    var projectSources: Set<ProjectSourceMock.ID> = []
    func getProjectSources(user: UserID) -> [ProjectSourceMock.ID] {
        projectSources
            .compactMap { $0.ref }
            .filter { $0.user == user }
            .map { $0.id }
    }
    
    var tickets: Deque<ProjectTicket> = []
    var eventHandlers: [SystemID: Handler<ProjectHubEvent>] = [:]
    
    
    // MARK: action
    func createProjectSource() async {
        // mutate
        while tickets.isEmpty == false {
            let ticket = tickets.removeFirst()
            let projectSourceRef = ProjectSourceMock(
                projectHubRef: self,
                user: ticket.user,
                name: ticket.name)
            let projectSource = projectSourceRef.id.value.uuidString
            projectSources.insert(projectSourceRef.id)
            
            let eventHandler = eventHandlers[ticket.system]
            let event = ProjectHubEvent.added(projectSource)
            
            // 직접 이벤트핸들러 호출
            eventHandler?.execute(event)
        }
    }
    
    
    // MARK: value
    struct ID: ServerObjectID {
        let value: UUID
        nonisolated init(value: UUID = UUID()) {
            self.value = value
        }
        typealias Object = ProjectHubMock
        typealias Manager = ProjectHubMockManager
    }
}


// MARK: ObjectManager
@Server
final class ProjectHubMockManager: ServerObjectManager {
    static var container: [ProjectHubMock.ID : ProjectHubMock] = [:]
}
