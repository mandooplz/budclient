//
//  ProjectSourceLink.swift
//  BudClient
//
//  Created by 김민우 on 6/26/25.
//
import Foundation
import Tools



// MARK: Link
public struct ProjectSourceLink: Sendable, Hashable {
    // MARK: core
    private let mode: SystemMode
    private let documentId: String
    public init(mode: SystemMode, id: String) {
        self.mode = mode
        self.documentId = id
    }
    
    
    // MARK: state
    @Server
    public func insert(_ ticket: ProjectTicket) async throws {
        switch mode {
        case .test:
            let projectSource = ProjectSourceMock.ID(documentId)
            projectSource.ref?.ticket = ticket
        case .real:
            guard let projectSource = ProjectHub.shared.getProjectSource(documentId),
                  let projectSourceRef = projectSource.ref else {
                throw Error.projectSourceDoesNotExist
            }
            projectSourceRef.insert(ticket)
        }
    }
    
    @Server
    public func hasHandler(system: SystemID) async throws -> Bool {
        switch mode {
        case .test:
            let projectSource = ProjectSourceMock.ID(documentId)
            
            guard let projectSourceRef = projectSource.ref else {
                throw Error.projectSourceDoesNotExist
            }
            
            return projectSourceRef.eventHandlers[system] != nil
        case .real:
            fatalError()
        }
    }
    @Server
    package func setHandler(ticket: Ticket, handler: Handler<ProjectSourceEvent>) async throws {
        switch mode {
        case .test:
            let projectSource = ProjectSourceMock.ID(documentId)
            
            guard let projectSourceRef = projectSource.ref else {
                throw Error.projectSourceDoesNotExist
            }
            
            projectSourceRef.eventHandlers[ticket.system] = handler
        case .real:
            fatalError()
        }
    }
    @Server
    package func removeHandler(system: SystemID) async throws {
        switch mode {
        case .test:
            let projectSource = ProjectSourceMock.ID(documentId)
            
            guard let projectSourceRef = projectSource.ref else {
                throw Error.projectSourceDoesNotExist
            }
            
            projectSourceRef.eventHandlers[system] = nil
            
        case .real:
            guard let projectSource = ProjectHub.shared.getProjectSource(documentId),
                  let projectSourceRef = projectSource.ref else {
                throw Error.projectSourceDoesNotExist
            }
            
            try await projectSourceRef.removeHandler(system: system)
        }
    }
    
    
    
    // MARK: action
    @Server
    public func processTicket() async throws {
        switch mode {
        case .test:
            let projectSource = ProjectSourceMock.ID(documentId)
            guard let projectSourceRef = projectSource.ref else {
                throw Error.projectSourceDoesNotExist
            }
            
            projectSourceRef.processTicket()
        case .real:
            guard let projectSource = ProjectHub.shared.getProjectSource(documentId),
                  let projectSourceRef = projectSource.ref else {
                throw Error.projectSourceDoesNotExist
            }
            
            try await projectSourceRef.processTicket()
        }
    }
    
    @Server
    public func remove() async throws {
        switch mode {
        case .test:
            let projectSource = ProjectSourceMock.ID(documentId)
            guard let projectSourceRef = projectSource.ref else {
                throw Error.projectSourceDoesNotExist
            }
            
            projectSourceRef.remove()
        case .real:
            guard let projectSource = ProjectHub.shared.getProjectSource(documentId),
                  let projectSourceRef = projectSource.ref else {
                throw Error.projectSourceDoesNotExist
            }
            
            try await projectSourceRef.remove()
        }
    }
    
    
    // MARK: value
    public enum Error: Swift.Error {
        case projectSourceDoesNotExist
    }
}
