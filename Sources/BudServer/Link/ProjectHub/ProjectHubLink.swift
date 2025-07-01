//
//  ProjectHubLink.swift
//  BudClient
//
//  Created by 김민우 on 6/26/25.
//
import Foundation
import Tools
import FirebaseFirestore


// MARK: Link
package struct ProjectHubLink: Sendable {
    // MARK: core
    private let mode: SystemMode
    private var listner: ListenSource?
    init(mode: SystemMode) {
        self.mode = mode
    }
    
    
    // MARK: state
    @BudServer
    package func getMyProjectSource(_ userId: String) async -> [ProjectSourceLink] {
        switch mode {
        case .test:
            ProjectHubMock.shared
                .getMyProjectSources(userId: userId)
                .map { ProjectSourceLink(mode: .test(mock: $0)) }
        case .real:
            fatalError()
        }
    }
    @BudServer
    package func insertTicket(_ ticket: Ticket) async {
        switch mode {
        case .test:
            ProjectHubMock.shared.tickets.insert(ticket.forTest())
        case .real:
            ProjectHub.shared.tickets.insert(ticket.forReal())
        }
    }
    
    
    // MARK: action
    @BudServer
    package func processTicket() async throws {
        switch mode {
        case .test:
            await ProjectHubMock.shared.processTickets()
        case .real:
            try await ProjectHub.shared.processTicket()
        }
    }
    @BudServer
    package func setNotifier(userId: UserID, notifier: Notifier) async throws {
        switch mode {
        case .test:
            ProjectHubMock.shared.handlers[userId] = notifier.forTest()
        case .real:
            await ProjectHub.shared.setNotifier(userId: userId, notifier: notifier)
        }
    }
    @BudServer
    package func removeNotifier(userId: UserID) async throws {
        switch mode {
        case .test:
            ProjectHubMock.shared.handlers[userId] = nil
        case .real:
            await ProjectHub.shared.removeNotifier()
        }
    }
    
    
    // MARK: value
    package struct Ticket {
        package let value: UUID
        package let userId: String
        package let purpose: Purpose
        
        package init(userId: String, for purpose: Purpose) {
            self.value = .init()
            self.userId = userId
            self.purpose = purpose
        }
        
        package enum Purpose {
            case createProjectSource
        }
        
        internal func forTest() -> ProjectHubMock.Ticket {
            switch purpose {
            case .createProjectSource:
                return .init(userId: userId, for: .createProjectSource)
            }
        }
        internal func forReal() -> ProjectHub.Ticket {
            switch purpose {
            case .createProjectSource:
                return .init(userId: userId, for: .createProjectSource)
            }
        }
    }
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
    package typealias UserID = String
}
