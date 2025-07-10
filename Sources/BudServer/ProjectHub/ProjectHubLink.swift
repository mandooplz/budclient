//
//  ProjectHubLink.swift
//  BudClient
//
//  Created by 김민우 on 6/26/25.
//
import Foundation
import Values
import BudServerMock
import BudServerLocal


// MARK: Link
package struct ProjectHubLink: Sendable {
    // MARK: core
    private let mode: Mode
    init(mode: Mode) {
        self.mode = mode
    }
    
    
    // MARK: state
    @Server
    package func insertTicket(_ ticket: CreateProjectSource) async {
        switch mode {
        case .test(let projectHubRef):
            projectHubRef.tickets.append(ticket)
        case .real:
            await MainActor.run {
                ProjectHub.shared.tickets.append(ticket)
            }
        }
    }
    
    
    @Server
    package func hasHandler(requester: ObjectID) async -> Bool {
        switch mode {
        case .test(let projectHubRef):
            return projectHubRef.hasHandler(requester: requester)
        case .real:
            return await ProjectHub.shared.hasHandler(requester: requester)
        }
    }
    @Server
    package func setHandler(requester: ObjectID, user: UserID, handler: Handler<ProjectHubEvent>) async {
        switch mode {
        case .test(let projectHubRef):
            projectHubRef.sethandler(requester: requester, handler: handler)
        case .real:
            await ProjectHub.shared.setHandler(requester: requester, user: user, handler: handler)
        }
    }
    @Server
    package func removeHandler(object: ObjectID) async {
        switch mode {
        case .test(let projectHubRef):
            projectHubRef.eventHandlers[object] = nil
        case .real:
            await ProjectHub.shared.removeHandler(object: object)
        }
    }
    
    @Server package func notifyModified(_ id: ProjectID) {
        switch mode {
        case .test(let projectHubMock):
            projectHubMock.notifyModified(id)
        case .real:
            return
        }
    }
    
    
    // MARK: action
    @Server
    package func createProjectSource() async throws {
        switch mode {
        case .test(let projectHubRef):
            await projectHubRef.createProjectSource()
        case .real:
            try await ProjectHub.shared.createProjectSource()
        }
    }
    
    
    // MARK: value
    enum Mode: Sendable {
        case test(ProjectHubMock)
        case real
    }
}
