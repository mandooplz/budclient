//
//  ProjectBoard.swift
//  BudClient
//
//  Created by 김민우 on 6/25/25.
//
import Foundation
import Tools
import BudServer


// MARK: Object
@MainActor @Observable
public final class ProjectBoard: Sendable {
    // MARK: core
    init(mode: SystemMode, budClient: BudClient.ID, userId: String) {
        self.id = ID(value: .init())
        self.mode = mode
        self.budClient = budClient
        self.userId = userId
        
        ProjectBoardManager.register(self)
    }
    internal func delete() {
        ProjectBoardManager.unregister(self.id)
    }
    
    
    // MARK: state
    public nonisolated let id: ID
    internal nonisolated let mode: SystemMode
    public nonisolated let budClient: BudClient.ID
    public nonisolated let userId: String
    
    public internal(set) var projects: [Project.ID] = []
    
    public var issue: (any Issuable)?
    
    
    // MARK: action
    public func startObserving() async { }
    public func stopObserving() async { }
    public func createEmptyProject() async {
        // capture
        let budServerLink = budClient.ref!.budServerLink!
        let projectHubLink = budServerLink.getProjectHub()
        
        // compute
        do {
            let ticket = ProjectHubLink.Ticket(userId: userId, for: .createProjectSource)
            await projectHubLink.insertTicket(ticket)
            try await projectHubLink.processTicket()
        } catch {
            issue = UnknownIssue(error)
            return
        }
        
        // mutate
        let projectRef = Project(mode: mode, projectBoard: id, userId: userId)
        projects.append(projectRef.id)
    }
    
    
    // MARK: value
    @MainActor
    public struct ID: Sendable, Hashable {
        public let value: UUID
        
        internal var isExist: Bool {
            ProjectBoardManager.container[self] != nil
        }
        public var ref: ProjectBoard? {
            ProjectBoardManager.container[self]
        }
    }
}


// MARK: Object Manager
@MainActor @Observable
fileprivate final class ProjectBoardManager: Sendable {
    // MARK: state
    fileprivate static var container: [ProjectBoard.ID: ProjectBoard] = [:]
    fileprivate static func register(_ object: ProjectBoard) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: ProjectBoard.ID) {
        container[id] = nil
    }
}

