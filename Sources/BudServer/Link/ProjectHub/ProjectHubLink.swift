//
//  ProjectHubLink.swift
//  BudClient
//
//  Created by 김민우 on 6/26/25.
//
import Foundation
import Tools


// MARK: Link
package struct ProjectHubLink: Sendable {
    // MARK: core
    private let mode: SystemMode
    init(mode: SystemMode) {
        self.mode = mode
    }
    
    
    // MARK: state
    @Server
    package func insertTicket(_ ticket: ProjectTicket) async {
        switch mode {
        case .test:
            ProjectHubMock.shared.tickets.insert(ticket)
        case .real:
            ProjectHub.shared.tickets.insert(ticket)
        }
    }
    
    
    @Server
    package func hasHandler(system: SystemID) async -> Bool {
        switch mode {
        case .test:
            return ProjectHubMock.shared.eventHandlers[system] != nil
        case .real:
            return await ProjectHub.shared.hasNotifier()
        }
    }
    @Server
    package func setHandler(ticket: Ticket, handler: Handler<ProjectHubEvent>) async throws {
        switch mode {
        case .test:
            ProjectHubMock.shared.eventHandlers[ticket.system] = handler
        case .real:
            await ProjectHub.shared.setNotifier(ticket: ticket, handler: handler)
        }
    }
    
    
    // MARK: action
    @Server
    package func createProjectSource() async throws {
        switch mode {
        case .test:
            await ProjectHubMock.shared.createProjectSource()
        case .real:
            try await ProjectHub.shared.createProjectSource()
        }
    }
    @Server
    package func removeNotifier(system: SystemID) async throws {
        switch mode {
        case .test:
            ProjectHubMock.shared.eventHandlers[system] = nil
        case .real:
            await ProjectHub.shared.removeNotifier()
        }
    }
}
