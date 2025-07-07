//
//  ProjectSourceLink.swift
//  BudClient
//
//  Created by 김민우 on 6/26/25.
//
import Foundation
import Values
import BudServerMock
import BudServerLocal



// MARK: Link
package struct ProjectSourceLink: Sendable, Hashable {
    // MARK: core
    private let mode: SystemMode
    package let object: ProjectSourceID
    private typealias TestManager = ProjectSourceMockManager
    private typealias RealManager = ProjectSourceManager
    package init(mode: SystemMode, object: ProjectSourceID) {
        self.mode = mode
        self.object = object
    }
    
    
    // MARK: state
    @Server package func insert(_ ticket: EditProjectSourceName) async throws {
        switch mode {
        case .test:
            TestManager.get(object)?.editTicket = ticket
        case .real:
           await MainActor.run {
               RealManager.get(object)?.editTicket = ticket
            }
        }
    }
    
    @Server package func hasHandler(object id: ObjectID) async -> Bool {
        switch mode {
        case .test:
            return TestManager.get(object)?.eventHandlers[id] != nil
        case .real:
            return await MainActor.run {
                return RealManager.get(object)?.hasHandler(object: id) ?? false
            }
        }
    }
    @Server package func setHandler(ticket: SubscrieProjectSource, handler: Handler<ProjectSourceEvent>) async {
        switch mode {
        case .test:
            TestManager.get(object)?.eventHandlers[ticket.object] = handler
        case .real:
            await MainActor.run {
                RealManager.get(object)?.setHandler(ticket: ticket, handler: handler)
            }
        }
    }
    @Server package func removeHandler(object id: ObjectID) async {
        switch mode {
        case .test:
            TestManager.get(object)?.eventHandlers[id] = nil
            
        case .real:
            await MainActor.run {
                RealManager.get(object)?.removeHandler(object: id)
            }
        }
    }
    
    package func isExist() async -> Bool {
        switch mode {
        case .test:
            return await TestManager.isExist(object)
        case .real:
            return await RealManager.isExist(object)
        }
    }
    
    
    
    // MARK: action
    @Server package func editProjectName() async throws {
        switch mode {
        case .test:
            TestManager.get(object)?.editProjectName()
        case .real:
            try await MainActor.run {
                try RealManager.get(object)?.editProjectName()
            }
        }
    }
    
    @Server package func remove() async {
        switch mode {
        case .test:
            TestManager.get(object)?.remove()
        case .real:
            await MainActor.run {
                RealManager.get(object)?.remove()
            }
        }
    }
}
