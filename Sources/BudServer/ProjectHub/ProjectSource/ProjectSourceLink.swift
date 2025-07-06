//
//  ProjectSourceLink.swift
//  BudClient
//
//  Created by 김민우 on 6/26/25.
//
import Foundation
import Tools
import BudServerMock



// MARK: Link
public struct ProjectSourceLink: Sendable, Hashable {
    // MARK: core
    private let mode: Mode
    package init(mode: Mode) {
        self.mode = mode
    }
    
    
    // MARK: state
    @Server
    public func insert(_ ticket: ProjectTicket) async throws {
        switch mode {
        case .test(let mock):
            guard let projectSourceRef = mock.ref else {
                throw Error.projectSourceDoesNotExist
            }
            
            projectSourceRef.ticket = ticket
        case .real(let object):
           try await MainActor.run {
               guard let projectSourceRef = object.ref else {
                    throw Error.projectSourceDoesNotExist
                }
               
                projectSourceRef.insert(ticket)
            }
        }
    }
    
    @Server
    public func hasHandler(system: SystemID) async throws -> Bool {
        switch mode {
        case .test(let mock):
            guard let projectSourceRef = mock.ref else {
                throw Error.projectSourceDoesNotExist
            }
            
            return projectSourceRef.eventHandlers[system] != nil
        case .real(let object):
            return try await MainActor.run {
                guard let projectSourceRef = object.ref else {
                    throw Error.projectSourceDoesNotExist
                }
                return projectSourceRef.hasHandler(system: system)
            }
        }
    }
    @Server
    package func setHandler(ticket: Ticket, handler: Handler<ProjectSourceEvent>) async throws {
        switch mode {
        case .test(let mock):
            guard let projectSourceRef = mock.ref else {
                throw Error.projectSourceDoesNotExist
            }
            
            projectSourceRef.eventHandlers[ticket.system] = handler
        case .real(let object):
            try await MainActor.run {
                guard let projectSourceRef = object.ref else {
                    throw Error.projectSourceDoesNotExist
                }
                projectSourceRef.setHandler(ticket: ticket, handler: handler)
            }
        }
    }
    @Server
    package func removeHandler(system: SystemID) async throws {
        switch mode {
        case .test(let mock):
            guard let projectSourceRef = mock.ref else {
                throw Error.projectSourceDoesNotExist
            }
            
            projectSourceRef.eventHandlers[system] = nil
            
        case .real(let object):
            try await MainActor.run {
                guard let projectSourceRef = object.ref else {
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
        case .test(let mock):
            guard let projectSourceRef = mock.ref else {
                throw Error.projectSourceDoesNotExist
            }
            
            projectSourceRef.processTicket()
        case .real(let object):
            try await MainActor.run {
                guard let projectSourceRef = object.ref else {
                    throw Error.projectSourceDoesNotExist
                }
                
                try projectSourceRef.processTicket()
            }
        }
    }
    
    @Server
    public func remove() async throws {
        switch mode {
        case .test(let mock):
            guard let projectSourceRef = mock.ref else {
                throw Error.projectSourceDoesNotExist
            }
            
            projectSourceRef.remove()
        case .real(let object):
            try await MainActor.run {
                guard let projectSourceRef = object.ref else {
                    throw Error.projectSourceDoesNotExist
                }
                
                projectSourceRef.remove()
            }
        }
    }
    
    
    // MARK: value
    package enum Mode: Sendable, Hashable {
        case test(ProjectSourceMock.ID)
        case real(ProjectSource.ID)
    }
    public enum Error: Swift.Error {
        case projectSourceDoesNotExist
    }
}
