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
    private let id: ProjectSourceID
    private typealias TestManager = ProjectSourceMockManager
    private typealias RealManager = ProjectSourceManager
    package init(mode: SystemMode, id: ProjectSourceID) {
        self.mode = mode
        self.id = id
    }
    
    
    // MARK: state
    @Server
    public func insert(_ ticket: ProjectTicket) async throws {
        switch mode {
        case .test:
            guard let projectSourceRef = TestManager.get(id) else {
                throw Error.projectSourceDoesNotExist
            }
            
            projectSourceRef.ticket = ticket
        case .real:
           try await MainActor.run {
                guard let projectSourceRef = RealManager.get(id) else {
                    throw Error.projectSourceDoesNotExist
                }
               
                projectSourceRef.insert(ticket)
            }
        }
    }
    
    @Server
    public func hasHandler(system: SystemID) async throws -> Bool {
        switch mode {
        case .test:
            guard let projectSourceRef = TestManager.get(id) else {
                throw Error.projectSourceDoesNotExist
            }
            
            return projectSourceRef.eventHandlers[system] != nil
        case .real:
            return try await MainActor.run {
                guard let projectSourceRef = RealManager.get(id) else {
                    throw Error.projectSourceDoesNotExist
                }
                return projectSourceRef.hasHandler(system: system)
            }
        }
    }
    @Server
    package func setHandler(ticket: Ticket, handler: Handler<ProjectSourceEvent>) async throws {
        switch mode {
        case .test:
            guard let projectSourceRef = TestManager.get(id) else {
                throw Error.projectSourceDoesNotExist
            }
            
            projectSourceRef.eventHandlers[ticket.system] = handler
        case .real:
            try await MainActor.run {            
                guard let projectSourceRef = RealManager.get(id) else {
                    throw Error.projectSourceDoesNotExist
                }
                projectSourceRef.setHandler(ticket: ticket, handler: handler)
            }
        }
    }
    @Server
    package func removeHandler(system: SystemID) async throws {
        switch mode {
        case .test:
            guard let projectSourceRef = TestManager.get(id) else {
                throw Error.projectSourceDoesNotExist
            }
            
            projectSourceRef.eventHandlers[system] = nil
            
        case .real:
            try await MainActor.run {
                guard let projectSourceRef = RealManager.get(id) else {
                    throw Error.projectSourceDoesNotExist
                }
                
                projectSourceRef.removeHandler(system: system)
            }
        }
    }
    
    
    
    // MARK: action
    @Server
    public func processTicket() async throws {
        switch mode {
        case .test:
            guard let projectSourceRef = TestManager.get(id) else {
                throw Error.projectSourceDoesNotExist
            }
            
            projectSourceRef.processTicket()
        case .real:
            try await MainActor.run {
                guard let projectSourceRef = RealManager.get(id) else {
                    throw Error.projectSourceDoesNotExist
                }
                
                projectSourceRef.processTicket()
            }
        }
    }
    
    @Server
    public func remove() async throws {
        switch mode {
        case .test:
            guard let projectSourceRef = TestManager.get(id) else {
                throw Error.projectSourceDoesNotExist
            }
            
            projectSourceRef.remove()
        case .real:
            try await MainActor.run {            
                guard let projectSourceRef = RealManager.get(id) else {
                    throw Error.projectSourceDoesNotExist
                }
                
                projectSourceRef.remove()
            }
        }
    }
    
    
    // MARK: value
    public enum Error: Swift.Error {
        case projectSourceDoesNotExist
    }
}
