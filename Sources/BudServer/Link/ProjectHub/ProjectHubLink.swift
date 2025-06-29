//
//  ProjectHubLink.swift
//  BudClient
//
//  Created by 김민우 on 6/26/25.
//
import Foundation
import Tools


// MARK: Link
public struct ProjectHubLink: Sendable {
    // MARK: core
    private let mode: SystemMode
    init(mode: SystemMode) {
        self.mode = mode
    }
    
    
    // MARK: state
    public func getMyProjectSource(_ userId: String) async -> [ProjectSourceLink] {
        switch mode {
        case .test:
            await ProjectHubMock.shared
                .getMyProjectSources(userId: userId)
                .map { ProjectSourceLink(mode: .test(mock: $0)) }
        case .real:
            fatalError()
        }
    }
    public func insertTicket(_ ticket: Ticket) async {
        switch mode {
        case .test:
            await MainActor.run {
                
            }
        case .real:
            fatalError()
        }
    }
    
    
    // MARK: action
    public func processTicket() async {
        switch mode {
        case .test:
            await ProjectHubMock.shared.processTickes()
        case .real:
            fatalError()
        }
    }
    
    
    // MARK: value
    public struct Ticket {
        public let value: UUID
        public let userId: String
        public let purpose: Purpose
        
        public init(userId: String, for purpose: Purpose) {
            self.value = .init()
            self.userId = userId
            self.purpose = purpose
        }
        
        public enum Purpose {
            case createProjectSource
        }
    }
}
