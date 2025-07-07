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
    public func insert(_ ticket: EditProjectSourceName) async throws {
        switch mode {
        case .test(let mock):
            guard let projectSourceRef = mock.ref else {
                throw Error.projectSourceDoesNotExist
            }
            
            projectSourceRef.editTicket = ticket
        case .real(let object):
           try await MainActor.run {
               guard let projectSourceRef = object.ref else {
                    throw Error.projectSourceDoesNotExist
                }
               
               projectSourceRef.editTicket = ticket
            }
        }
    }
    
    @Server
    public func hasHandler(object: ObjectID) async throws -> Bool {
        switch mode {
        case .test(let mock):
            guard let projectSourceRef = mock.ref else {
                throw Error.projectSourceDoesNotExist
            }
            
            return projectSourceRef.eventHandlers[object] != nil
        case .real(let real):
            return try await MainActor.run {
                guard let projectSourceRef = real.ref else {
                    throw Error.projectSourceDoesNotExist
                }
                return projectSourceRef.hasHandler(object: object)
            }
        }
    }
    @Server
    package func setHandler(ticket: SubscrieProjectSource, handler: Handler<ProjectSourceEvent>) async throws {
        switch mode {
        case .test(let mock):
            guard let projectSourceRef = mock.ref else {
                throw Error.projectSourceDoesNotExist
            }
            
            projectSourceRef.eventHandlers[ticket.object] = handler
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
    package func removeHandler(object: ObjectID) async throws {
        switch mode {
        case .test(let mock):
            guard let projectSourceRef = mock.ref else {
                throw Error.projectSourceDoesNotExist
            }
            
            projectSourceRef.eventHandlers[object] = nil
            
        case .real(let real):
            try await MainActor.run {
                guard let projectSourceRef = real.ref else {
                    throw Error.projectSourceDoesNotExist
                }
                
                projectSourceRef.removeHandler(object: object)
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
