//
//  ProjectBoard.swift
//  BudClient
//
//  Created by 김민우 on 6/25/25.
//
import Foundation
import Tools
import BudServer

import os
let logger = Logger()


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
    internal nonisolated let id: ID
    internal nonisolated let mode: SystemMode
    public nonisolated let budClient: BudClient.ID
    
    public nonisolated let userId: String
    internal var updater: ProjectBoardUpdater.ID?
    
    public internal(set) var projects: [Project.ID] = []
    internal var projectSourceMap: [ProjectSourceID: Project.ID] = [:]
    
    public var issue: (any Issuable)?
    
    
    // MARK: action
    public func setUp() {
        // mutate
        if self.updater != nil { return }
        let updaterRef = ProjectBoardUpdater(mode: mode,
                                             projectBoard: self.id)
        self.updater = updaterRef.id
    }
    
    public func startObserving() async {
        await self.startObserving(addCallback: nil, removeCallback: nil)
    }
    internal func startObserving(addCallback: Hook? = nil,
                                 removeCallback: Hook? = nil) async {
        // capture
        let budServerLink = budClient.ref!.budServerLink!
        let projectHubLink = budServerLink.getProjectHub()
        
        // compute
        do {
            try await projectHubLink.setNotifier(
                userId: userId,
                notifier: .init(
                    added: { projectSource in
                        Task { @MainActor in
                            guard let updaterRef = self.updater?.ref else { return }
                            
                            updaterRef.diffs.insert(.added(projectSource: projectSource))
                            updaterRef.update()
                            
                            await addCallback?()
                        }
                    },
                    removed: { projectSource in
                        Task { @MainActor in
                            guard let updaterRef = self.updater?.ref else { return }
                            updaterRef.diffs.insert(.removed(projectSource: projectSource))
                            updaterRef.update()
                            await removeCallback?()
                        }
                    }))
        } catch {
            issue = UnknownIssue(error)
            return
        }
    }
    
    public func stopObserving() async {
        // ProjectHubLink을 통해 notifier를 삭제한다.
        let budServerLink = budClient.ref!.budServerLink!
        let projectHubLink = budServerLink.getProjectHub()
        
        // compute
        do {
            try await projectHubLink.removeNotifier(userId: userId)
        } catch {
            issue = UnknownIssue(error)
            return
        }
    }
    
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
    internal typealias ProjectSourceID = String
    public enum Error: String, Swift.Error {
        case updaterIsNotSet
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

