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
    package func insertTicket(_ ticket: Ticket) async {
        switch mode {
        case .test:
            ProjectHubMock.shared.tickets.insert(ticket)
        case .real:
            ProjectHub.shared.tickets.insert(ticket)
        }
    }
    
    
    @Server
    package func hasNotifier(system: SystemID) async -> Bool {
        switch mode {
        case .test:
            return ProjectHubMock.shared.notifiers[system] != nil
        case .real:
            return await ProjectHub.shared.hasNotifier()
        }
    }
    @Server
    package func setNotifier(ticket: Ticket, notifier: Notifier) async throws {
        switch mode {
        case .test:
            ProjectHubMock.shared.notifiers[ticket.system] = notifier.forTest()
        case .real:
            await ProjectHub.shared.setNotifier(ticket: ticket, notifier: notifier)
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
            ProjectHubMock.shared.notifiers[system] = nil
        case .real:
            await ProjectHub.shared.removeNotifier()
        }
    }
    
    
    // MARK: value
    // Notifier를 어떻게 수정할 것인가. 
    package struct Notifier: Sendable {
        package let added: Handler
        package let removed: Handler
        
        package init(added: @escaping Handler, removed: @escaping Handler) {
            self.added = added
            self.removed = removed
        }
        
        package typealias Handler = @Sendable (ProjectSourceID) -> Void
        package typealias ProjectSourceID = String
        
        internal func forTest() -> ProjectHubMock.Notifier {
            .init(added: added, removed: removed)
        }
    }
}
