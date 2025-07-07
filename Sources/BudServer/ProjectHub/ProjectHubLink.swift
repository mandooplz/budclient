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
    package func hasHandler(object: ObjectID) async -> Bool {
        switch mode {
        case .test(let projectHubRef):
            return projectHubRef.eventHandlers[object] != nil
        case .real:
            return await ProjectHub.shared.hasHandler()
        }
    }
    @Server
    package func setHandler(ticket: SubscribeProjectHub, handler: Handler<ProjectHubEvent>) async {
        switch mode {
        case .test(let projectHubRef):
            projectHubRef.eventHandlers[ticket.object] = handler
        case .real:
            await ProjectHub.shared.setHandler(ticket: ticket, handler: handler)
        }
    }
    @Server
    package func removeHandler(object: ObjectID) async {
        switch mode {
        case .test(let projectHubRef):
            projectHubRef.eventHandlers[object] = nil
        case .real:
            await ProjectHub.shared.removeHandler()
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
    enum Event: Sendable {
        case added(ProjectSourceLink)
        case removed(ProjectSourceLink)
    }
}
